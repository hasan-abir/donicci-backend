module ImagekitHelper
    private

    def upload_image_to_cloud(image_file)
        imagekitio = ImageKitIo.client
        filename = image_file.original_filename

        upload_response = imagekitio.upload_file(file: image_file, file_name: filename, folder: "donicci-products")

        if upload_response[:status_code] == "200"
            {fileId: upload_response[:response]["fileId"], url: upload_response[:response]["url"]}
        else
            {error: upload_response[:error]["message"]}
        end
    end
end
