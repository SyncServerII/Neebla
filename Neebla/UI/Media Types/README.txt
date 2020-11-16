There can be more than one Media Type for each Item Type.
E.g., Camera Media Type and Photo Library both provide the Image Item Type.

MediaTypes correspond 1:1 to SyncServer objectType's. They are used to represent objects with View's given objectType's.

To add a new Object Type:

    1) Add a new Item Type in the
        ItemTypeManager.swift
        
    2) Add an icon type, and add it into
        AnyIcon.swift
    
    3) Need at least one Media Type in
        MediaTypeListView.swift
