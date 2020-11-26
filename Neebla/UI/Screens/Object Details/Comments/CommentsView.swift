
import Foundation
import SwiftUI

struct CommentsView: UIViewControllerRepresentable {
    class Coordinator: NSObject {
        override init() {
        }
    }
    
    let commentFile: ServerFileModel
    @Environment(\.presentationMode) var isPresented
    
    init(commentFile: ServerFileModel) {
        self.commentFile = commentFile
    }
        
    func makeUIViewController(context: Context) -> DiscussionVC {
        let discussionVC = DiscussionVC()
        discussionVC.setup(discussion: commentFile, delegate: nil)
        return discussionVC
    }

    func updateUIViewController(_ uiViewController: DiscussionVC, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}
