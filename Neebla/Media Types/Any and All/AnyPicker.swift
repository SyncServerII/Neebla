
import Foundation

struct AnyPicker {
    // Note that this list doesn't map exactly to media types.
    // Some pickers allow upload of more than one media type. E.g., still images and live images by the PhotoLibraryMediaPicker.
    // Multiple pickers are needed for some media types. E.g., PhotoLibraryMediaPicker and CameraMediaPicker both support still images.
    static func forAlbum(itemPicked: @escaping (UploadableMediaAssets)->()) -> [MediaPicker] {
        return [
            // The order in which the pickers are listed here is the order in which they appear in the UI as choices for the user.
            URLMediaPicker(itemPicked: itemPicked),
            CameraMediaPicker(itemPicked: itemPicked),
            PhotoLibraryMediaPicker(itemPicked: itemPicked),
        ]
    }
}

