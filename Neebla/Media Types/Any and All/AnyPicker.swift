
import Foundation

struct AnyPicker {
    // Note that this list doesn't map exactly to media types.
    // Some pickers allow upload of more than one media type. E.g., still images and live images by the PhotoLibraryPicker.
    // Multiple pickers are needed for some media types. E.g., PhotoLibraryPicker and CameraMediaType both support still images.
    static func forAlbum(itemPicked: @escaping (UploadableMediaAssets)->()) -> [MediaPicker] {
        return [
            CameraMediaPicker(itemPicked: itemPicked),
            PhotoLibraryMediaPicker(itemPicked: itemPicked),
            URLMediaPicker(itemPicked: itemPicked)
        ]
    }
}

