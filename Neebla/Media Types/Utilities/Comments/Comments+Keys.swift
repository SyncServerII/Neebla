
import Foundation

extension Comments {
    enum Keys {
        // 4/29/18; I have changed from `image` terminology (e.g., imageUUIDKey) to `media` terminlogy. But, of course, the keys themselves need to stay the same-- as they reflect what is in actual files.
        
        // 12/12/20; I'm keeping this named as `mediaUUIDKey`-- as historically it mean the primary media for the object. (This is outdated now, of course, since any given object -- such as a live photo -- can have multiple media files).
        // This is so that we have the possibility of reconstructing the media/discussions if we lose the server data. This will explicitly connect the discussion to the media.
        // [1] It is important to note that we are *never* depending on this UUID value in app operation. This is more of a comment. While unlikely, it is possible that a user could modify this value in a discussion JSON file in cloud storage. Thus, it has unreliable contents in some real sense. See also https://github.com/crspybits/SharedImages/issues/145
        static let mediaUUIDKey = "imageUUID"
        
        // Referencing a movie file media.
        static let movieUUIDKey = "movieUUID"
        
        // For the same reasons as `mediaUUIDKey`, this is a comment.
        static let urlPreviewImageUUIDKey = "urlPreviewImageUUID"
        
        static let gifPreviewImageUUIDKey = "gifPreviewImageUUID"
        
        // 4/17/18; For some early files, image titles were stored in appMetaData. After server version 0.14.0, they are stored in "discussion" files. While the image title is stored in the "discussion" file-- that's for purposes of upload and download.
        static let mediaTitleKey = "imageTitle"

        // See MediaItemAttributes in ChangeResolvers
        static let mediaItemAttributesKey = "mediaItemAttributes"
    }
}

