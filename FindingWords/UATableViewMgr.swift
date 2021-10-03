//---- UATableViewMgr.swift ----
import Cocoa

class UATableViewMgr: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    //ソートステータス：今どの列が昇順または降順でソート済か
    var sortStatus: (columnName: String, accending: Bool) = ("", false)
    //--------------------------------------------------------------------------
    // NSTableViewSataSource/Delegate
    //--------------------------------------------------------------------------
    func numberOfRows(in tableView: NSTableView) -> Int{
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        return appDelegate.resultList.count
    }
    func tableView(_ tableView: NSTableView,
                   viewFor column: NSTableColumn?,
                   row: Int) -> NSView?{
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        guard let identifier = column?.identifier else{
            return nil
        }
        let celView = tableView.makeView(withIdentifier: identifier ,
                                         owner: self) as! NSTableCellView
        var value = ""
        switch identifier.rawValue {
        case "folder" :
            value = appDelegate.resultList[row].folder
        case "file" :
            value = appDelegate.resultList[row].file
        case "count" :
            value = String(appDelegate.resultList[row].count)
            celView.textField?.alignment = .right
        case "size" :
            value = String(appDelegate.resultList[row].size)
            celView.textField?.alignment = .right
        default:
            break
        }
        celView.textField?.stringValue = value
        return celView
    }
    //--------------------------------------------------------------------------
    //NSTableViewDelegate 列見出しのクリック・ソート
    //--------------------------------------------------------------------------
    func tableView(_ tableView: NSTableView,
                   didClick column: NSTableColumn){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        //ソート未済の時はaccendingから始める
        var flg = true
        //ソート済の時は反転する
        if sortStatus.columnName == column.identifier.rawValue{
            flg = !sortStatus.accending
        }
        switch column.identifier.rawValue {
        case "folder":
            sortByPath(accending: flg)
        case "file":
            sortByFile(accending: flg)
        case "count":
            sortByCount(accending: flg)
        case "size":
            sortBySize(accending: flg)
        default:
            break
        }
        appDelegate.tableView.reloadData()
        appDelegate.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        sortedTitle()
    }
    //--------------------------------------------------------------------------
    //ソート関数定義・パス名
    //--------------------------------------------------------------------------
    func sortByPath(accending: Bool){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        sortStatus = ("folder", accending)
        appDelegate.resultList.sort( by:{ lRecord, rRecord -> Bool in
            var flg = false
            if lRecord.folder < rRecord.folder{
                flg = true
            }else if lRecord.folder == rRecord.folder{
                if lRecord.file < rRecord.file{
                    flg = true
                }
            }
            if !accending{
                flg = !flg
            }
            return flg
        })
        
    }
    //--------------------------------------------------------------------------
    //ソート関数定義・ファイル名
    //--------------------------------------------------------------------------
    func sortByFile(accending: Bool){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate

        sortStatus = ("file", accending)
        appDelegate.resultList.sort( by:{ lRecord, rRecord -> Bool in
            var flg = false
            if lRecord.file < rRecord.file{
                flg = true
            }else if lRecord.file == rRecord.file{
                if lRecord.folder < rRecord.folder{
                    flg = true
                }
            }
            if !accending{
                flg = !flg
            }
            return flg
        })
    }
    //--------------------------------------------------------------------------
    //ソート関数定義・件数
    //--------------------------------------------------------------------------
    func sortByCount(accending: Bool){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate

        sortStatus = ("count", accending)
        appDelegate.resultList.sort( by:{ lRecord, rRecord -> Bool in
            var flg = false
            if lRecord.count < rRecord.count{
                flg = true
            }else if lRecord.count == rRecord.count{
                if lRecord.folder < rRecord.folder{
                    flg = true
                }else if lRecord.folder == rRecord.folder{
                    if lRecord.file < rRecord.file{
                        flg = true
                    }
                }
            }
            if !accending{
                flg = !flg
            }
            return flg
        })
    }
    //--------------------------------------------------------------------------
    //ソート関数定義・サイズ
    //--------------------------------------------------------------------------
    func sortBySize(accending: Bool){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate

        sortStatus = ("size", accending)
        appDelegate.resultList.sort( by:{ lRecord, rRecord -> Bool in
            var flg = false
            if lRecord.size < rRecord.size{
                flg = true
            }else if lRecord.size == rRecord.size{
                if lRecord.folder < rRecord.folder{
                    flg = true
                }else if lRecord.folder == rRecord.folder{
                    if lRecord.file < rRecord.file{
                        flg = true
                    }
                }
            }
            if !accending{
                flg = !flg
            }
            return flg
        })
    }
    //--------------------------------------------------------------------------
    // private method
    //--------------------------------------------------------------------------
    //ソートした列のタイトルに矢印を表示する
    func sortedTitle(){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        for column in appDelegate.tableView.tableColumns{
            let id = column.identifier.rawValue
            guard let title = appDelegate.columnTitles[id] else{
                return
            }
            if id == sortStatus.columnName{
                //ソート対象列
                if sortStatus.accending{
                    column.title = title + "↑"
                }else{
                    column.title = title + "↓"
                }
            }else{
                column.title = title
            }
        }
    }
}
