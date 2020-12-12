
import SwiftUI

struct DeveloperScreen: View {
    @ObservedObject var model = DeveloperScreenModel()
    
    var body: some View {
        MenuNavBar(title: "Developer") {
            List {
                Section(header: Text("ServerObjectModel's")) {
                    ForEach(model.objects, id: \.fileGroupUUID) { object in
                        DeveloperScreenModelRow(object: object)
                    }
                }
                                
                Section(header: Text("File's")) {
                    ForEach(model.objectDirectoryFiles, id: \.self) { filePath in
                        DeveloperScreenFileRow(path: filePath)
                    }
                }
            }.onAppear() {
                model.update()
            }
        }
    }
}

private struct DeveloperScreenModelRow: View {
    let object:ServerObjectModel
    let title: String?
    
    var nonnilTitle: String {
        title ?? "(Untitled)"
    }
    
    var deleted: String {
        object.deleted ? "(D) ": ""
    }
    
    init(object:ServerObjectModel) {
        self.object = object
        title = try? Comments.displayableMediaTitle(for: object)
    }
    
    var body: some View {
        Text(deleted + object.objectType + " / Title: " + nonnilTitle)
    }
}

private struct DeveloperScreenFileRow: View {
    let filename:String
    
    init(path: String) {
        if let url = URL(string: path) {
            filename = url.lastPathComponent
        }
        else {
            filename = "(No filename)"
        }
    }
    
    var body: some View {
        Text(filename)
    }
}
