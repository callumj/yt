require 'yt/collections/base'
require 'yt/models/asset'

module Yt
  module Collections
    # Provides methods to interact with a collection of Content ID assets.
    #
    # Resources with assets are: {Yt::Models::ContentOwner content owners}.
    class Assets < Base
      def insert(attributes = {})
        underscore_keys! attributes
        body = {type: attributes[:type]}
        params = {on_behalf_of_content_owner: @auth.owner_name}
        do_insert(params: params, body: body)
      end

    private

      # @return [Hash] the parameters to submit to YouTube to list assets
      #   owned by the content owner.
      # @see https://developers.google.com/youtube/partner/docs/v1/assets/list
      def list_params
        super.tap do |params|
          params[:path] = '/youtube/partner/v1/assets'
          params[:params] = assets_params
        end
      end

      def assets_params
        apply_where_params! on_behalf_of_content_owner: @auth.owner_name
      end

      # @return [Hash] the parameters to submit to YouTube to add a asset.
      # @see https://developers.google.com/youtube/partner/docs/v1/assets/insert
      def insert_params
        super.tap do |params|
          params[:path] = '/youtube/partner/v1/assets'
        end
      end
    end
  end
end