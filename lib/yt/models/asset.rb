require 'yt/models/base'
require 'yt/models/asset_metadata'

module Yt
  module Models
    # Provides methods to interact with YouTube ContentID assets.
    # @see https://developers.google.com/youtube/partner/docs/v1/assets
    class Asset < Base
      attr_reader :auth

      def initialize(options = {})
        @data = options.fetch(:data, {})
        @id = options[:id]
        @auth = options[:auth]
      end

      def update(attributes = {})
        underscore_keys! attributes
        do_patch body: attributes
        true
      end

      # @!attribute [r] ownership
      #   @return [Yt::Models::Ownership] the asset’s ownership.
      has_one :ownership
      delegate :general_owners, :performance_owners, :synchronization_owners,
        :mechanical_owners, to: :ownership

      def metadata_mine
        @metadata_mine ||= metadata('mine')
      end

      def metadata_effective
        @metadata_effective ||= metadata('effective')
      end

      # Soft-deletes the asset.
      # @note YouTube API does not provide a +delete+ method for the Asset
      #   resource, but only an +update+ method. Updating the +status+ of a
      #   Asset to "inactive" can be considered a soft-deletion.
      # @note Despite what the documentation says, YouTube API never returns
      #   the status of an asset, so it’s impossible to update, although the
      #   documentation says this should be the case. If YouTube ever fixes
      #   the API, then the following code can be uncommented.
      # @return [Boolean] whether the asset is inactive.
      # def delete
      #   body = {id: id, status: :inactive}
      #   do_patch(body: body) {|data| @data = data}
      #   inactive?
      # end

      # @return [String] the ID that YouTube assigns and uses to uniquely
      #   identify the asset.
      has_attribute :id

      # @return [String] the asset’s type. This value determines the metadata
      #   fields that you can set for the asset. In addition, certain API
      #   functions may only be supported for specific types of assets. For
      #   example, composition assets may have more complex ownership data than
      #   other types of assets.
      #   Valid values for this property are: art_track_video, composition,
      #   episode, general, movie, music_video, season, show, sound_recording,
      #   video_game, and web.
      has_attribute :type

# Status

      STATUSES = %q(active inactive pending)

      # @return [String] the asset’s status. Valid values are: active,
      #   inactive, and pending.
      # @note Despite what the documentation says, YouTube API never returns
      #   the status of an asset, so it’s impossible to update, although the
      #   documentation says this should be the case. If YouTube ever fixes
      #   the API, then the following code can be uncommented.
      # has_attribute :status
      #
      # # @return [Boolean] whether the asset is active.
      # def active?
      #   status == 'active'
      # end
      #
      # # @return [Boolean] whether the asset is inactive.
      # def inactive?
      #   status == 'inactive'
      # end
      #
      # # @return [Boolean] whether the asset is pending.
      # def pending?
      #   status == 'pending'
      # end

    private
    
      def metadata(type)
        raise ArgumentError.new("Invalid metadata type") unless ['mine', 'effective'].include?(type)
        metadata_param = "metadata#{type.capitalize}"
        if @data[metadata_param].present?
          Yt::Models::AssetMetadata.new(data: @data[metadata_param])
        else
          Yt::Collections::Assets.new(auth: @auth).where(id: id, fetch_metadata: type).first.send(:metadata, type)
        end
      end

      # @see https://developers.google.com/youtube/partner/docs/v1/assets/patch
      def patch_params
        super.tap do |params|
          params[:expected_response] = Net::HTTPOK
          params[:path] = "/youtube/partner/v1/assets/#{@id}"
          params[:params] = {on_behalf_of_content_owner: @auth.owner_name}
        end
      end
    end
  end
end