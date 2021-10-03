//---- AppDelegate.swift ----
import Cocoa
//検索条件・AND/OR
enum Condition: Int{
    case AND = 0
    case OR = 1
}
//検索方法・range of/regex
enum Method: Int{
    case RangeOf = 0
    case Regex = 1
}
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,NSWindowDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var tableView: NSTableView!          //結果結果出力フィールド
    @IBOutlet weak var searchButton: NSButton!          //検索ボタン
    @IBOutlet weak var pathNameField: NSTextField!      //検索フォルダ入力フィールド
    @IBOutlet weak var keywordField: NSTextField!       //検索キーワード入力フィールド
    @IBOutlet weak var extensionField: NSTextField!     //拡張子入力フィールド
    @IBOutlet weak var exclusion: NSButton!             //拡張子の除外指定
    @IBOutlet weak var countField: NSTextField!         //該当ファイル数出力フィールド
    @IBOutlet weak var condMatrix: NSMatrix!            //AND・OR検索指定
    @IBOutlet weak var elapsField: NSTextField!         //処理時間出力フィールド
    @IBOutlet weak var seachMethodMenu: NSMenu!         //検索方法メニュー
    @IBOutlet weak var applicationMenu: NSMenu!         //アプリケーションメニュー
    @IBOutlet weak var caseInsentiveMenu: NSMenu!       //大文字・小文字の区別メニュー
    
    var resultList = [Result]()                         //検索結果リスト
    var searchMgr = UASearchMgr.init()                    //テキスト検索オブジェクト
    var tableViewMgr = UATableViewMgr.init()            //テーブルビューコントローラ
    let alert = NSAlert()                               //メッセージダイアログ
    
    //ウィンドウサイズ
    var windowDef: [String:CGFloat] = ["width":500, "height":400]
    //列の識別子と並び
    var columnIds = ["folder", "file", "count", "size"]
    //列の幅
    var columnWidths: [String:CGFloat] = ["folder":120, "file":200, "count":70, "size":70]
    //列のタイトル
    let columnTitles = ["folder":"フォルダ", "file":"ファイル", "count":"語数", "size":"サイズ"]
    //ファイルを開くときのアプリケーション
    let applications = ["/Applications/Visual Studio Code.app",
                        "/Applications/Xcode.app",
                        "/Applications/mi.app",
                        "/Applications/Safari.app"]
    var currentAppIndex = 0 //選択中のアプリケーション
    //plistファイル（メニュー設定値他）
    let plistURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/DirectoryTraverse.plist")
    //結果一覧ファイル
    let outText = URL.init(fileURLWithPath:NSHomeDirectory() + "/Documents/DirectoryTraverse.txt")
    //オープンパネルのデフォルトパス名
    let defaultOpenPath = "/Users/itohisao/Desktop/NewPractice_Swift"
    
    //--------------------------------------------------------------------------
    // アプリケーション起動時
    //--------------------------------------------------------------------------
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //デリゲートの引き受け
        window.delegate = self
        tableView.delegate = tableViewMgr
        tableView.dataSource = tableViewMgr
        //背景色
        //window.contentView?.wantsLayer = true
        //window.contentView?.layer?.backgroundColor = NSColor.darkGray.cgColor
        //ユーザデフォルトの読み込み
        if let windowDef = UserDefaults.standard.dictionary(forKey: "windowDef")
               as? [String:CGFloat],
           let columnIds = UserDefaults.standard.array(forKey: "columnIds")
               as? [String],
           let columnWidths = UserDefaults.standard.dictionary(forKey: "columnWidths")
               as? [String:CGFloat]{
            self.windowDef = windowDef          //ウィンドウのサイズ
            self.columnIds = columnIds          //列の識別子と並び
            self.columnWidths = columnWidths    //列の幅
        }
        //コントロールプロパティの設定
        self.searchButton.keyEquivalent = "\r" //検索ボタンのキー登録・リターンキー
        //ウィンドウサイズ
        if let width = windowDef["width"], let height = windowDef["height"]{
            self.window.setContentSize(NSMakeSize(width, height))
        }
        //テーブルビューの列の再配置
        self.rearrange()
        //テーブルビューのファイルを開くアクションの定義
        tableView.target = self
        tableView.doubleAction = #selector(self.openFile(_:))
      
        //AND・OR検索指定 デフォルト:AND
        condMatrix.selectCell(withTag: Condition.AND.rawValue)
        //拡張子の除外指定 デフォルト:off
        exclusion.state = .off
        
        //メニュー・検索方法
        for item in seachMethodMenu.items{
            item.state = .off //初期化 全てoff
            item.target = self
            item.action = #selector(self.selectSeachMethod(_:)) //指定の変更メソッド
        }
        //デフォルト値の指定・RangOf検索
        self.seachMethodMenu.items[0].state = .on
        searchMgr.searchMethod = .RangeOf
        
        //メニュー・アプリケーション
        for item in applicationMenu.items{
            item.state = .off //初期化 全てoff
            item.target = self
            item.action = #selector(self.selectApplication(_:))
        }
        //デフォルト値の指定・アプリケーションテーブルの１番目
        self.applicationMenu.items[0].state = .on
        self.currentAppIndex = 0
        
        //メニュー・大文字・小文字の区別
        for item in caseInsentiveMenu.items{
            item.target = self
            item.action = #selector(self.selectCaseInsentive(_:))
            item.state = .off
        }
        //デフォルト値の指定・区別しない
        caseInsentiveMenu.items[0].state = .on
        searchMgr.caseInsensitive = true
    
        //plistを読み込み、前回セッション終了時のメニュー選択値を取得し、更新する
        if let dict = NSDictionary.init(contentsOf: plistURL){
            //検索方法
            if let value = dict["seachMethodMenu"] as? Int{
                menuSetItem(seachMethodMenu, value) //メニューの選択値の更新
                if let item = Method.init(rawValue: value){
                    searchMgr.searchMethod = item      //プロパティの更新
                }
            }
            //アプリケーション
            if let value = dict["applicationMenu"] as? Int{
                menuSetItem(applicationMenu, value) //メニューの選択値の更新
                currentAppIndex = value             //プロパティの更新
            }
            //大文字・小文字の区別
            if let value = dict["caseInsentiveMenu"] as? Int{
                menuSetItem(caseInsentiveMenu, value)       //メニューの選択値の更新
                searchMgr.caseInsensitive = value.boolValue    //プロパティの更新
            }
            //検索フォルダ名  AppSandbox is OFF
            if let value = dict["pathName"] as? String{
                pathNameField.stringValue = value
            }else{
                //デフォルトのパス名
                pathNameField.stringValue = defaultOpenPath
            }
        }
        //検索語フィールドをファーストレスポンダにする
        window.makeFirstResponder(keywordField)
    }
    //--------------------------------------------------------------------------
    //オープンパネルからディレクトリを選択する
    //--------------------------------------------------------------------------
    @IBAction func selectDir(_ sender: NSButton){
        let openPanel = NSOpenPanel.init()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "ディレクトリを選択する"
        
        var openPath = pathNameField.stringValue
        if openPath.count == 0{
            //パス未入力（長さゼロの文字列）
            openPath = defaultOpenPath
        }
        let url = NSURL.fileURL(withPath: openPath)
        //最初に位置付けるディレクトリパス
        openPanel.directoryURL = url
        //オープンパネルを開く
        openPanel.beginSheetModal(for: self.window, completionHandler: { (result) in
            if result == .OK{
                //ディレクトリの選択
                let selectedUrl = openPanel.urls[0]
                self.pathNameField.stringValue = selectedUrl.path
            }
        })
    }
    //--------------------------------------------------------------------------
    //検索
    //--------------------------------------------------------------------------
    @IBAction func sreach(_ sender: NSButton){
        searchMgr.search()
        //テーブルビューの編集・表示
        tableView.reloadData()
        tableViewMgr.sortByPath(accending: true)
        tableViewMgr.sortedTitle()
        
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        window.makeFirstResponder(tableView)
    }
    //--------------------------------------------------------------------------
    //一覧表示
    //--------------------------------------------------------------------------
    @IBAction func displayAll(_ sender: NSButton){
        var text = ""
        for result in resultList{
            let strCount = String(format:"%ld", result.count)
            let strSize = String(format:"%ld", result.size)
            text += result.fullPath + "\t" + strCount + "\t" + strSize + "\n"
        }
        let outText = URL.init(fileURLWithPath:NSHomeDirectory() + "/Documents/DirectoryTraverse.txt")
        do{
            try text.write(to: outText, atomically: true, encoding: .utf8)
        }catch{
            alert.messageText = "ファイル出力エラー"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            return
        }
        NSWorkspace.shared.openFile(outText.path,
                                    withApplication:self.applications[self.currentAppIndex])
    }
    //--------------------------------------------------------------------------
    //NSWindowDelegate：ウィンドウクローズ
    //--------------------------------------------------------------------------
    func windowWillClose(_ notification: Notification) {
        //現状のUIプロパティをユーザデフォルトに保存する
        //ウィンドウのサイズ
        windowDef["width"] = self.window.contentView?.frame.size.width
        windowDef["height"] = self.window.contentView?.frame.size.height
        //テーブルビューの列の幅
        columnIds.removeAll()
        for i in 0..<self.tableView.tableColumns.count{
            let id = self.tableView.tableColumns[i].identifier.rawValue
            columnIds.append(id)
            columnWidths[id] = self.tableView.tableColumns[i].width
        }
        UserDefaults.standard.set(windowDef, forKey: "windowDef")
        UserDefaults.standard.set(columnIds, forKey: "columnIds")
        UserDefaults.standard.set(columnWidths, forKey: "columnWidths")
        //メニュー選択値と選択フォルダ名をplistに保存する
        let plist: NSDictionary = ["seachMethodMenu": menuCurrentItem(seachMethodMenu),
                                   "applicationMenu": menuCurrentItem(applicationMenu),
                                   "caseInsentiveMenu": menuCurrentItem(caseInsentiveMenu),
                                   "pathName": pathNameField.stringValue]
        plist.write(to: plistURL, atomically: true)
    }
    //--------------------------------------------------------------------------
    // NSApplicationDelegate：ウィンドウの再表示
    //----------let text = try? String(contentsOf: url)----------------------------------------------------------------
    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool{
        if !flag{
            window.makeKeyAndOrderFront(self)
        }
        return true
    }
    //--------------------------------------------------------------------------
    //ファイルを開く
    //--------------------------------------------------------------------------
    @objc private func openFile(_ sender: NSButton){
        let index = tableView.selectedRow
        NSWorkspace.shared.openFile(resultList[index].fullPath,
                                    withApplication:self.applications[self.currentAppIndex])
    }
    //--------------------------------------------------------------------------
    //テーブルビューの列の再配置（前回セッション終了時の並びを再現する）
    //--------------------------------------------------------------------------
    private func rearrange(){
        //xibで定義されたTableViewオブジェクトの列の並びを前回セッション終了時の並びに入れ替える
        var tempArray = [NSTableColumn]() //一時配列
        for i in 0 ..< columnIds.count{
            var index: Int = -1
            //xib定義上の列の位置（index）を求める
            index = tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(columnIds[i]))
            if index > -1 {
                //xibで定義されたTableViewオブジェクトを取得する
                let columnObject = tableView.tableColumns[index]
                if let width = columnWidths[columnIds[i]]{
                    columnObject.width = width  //列の幅を設定する（前回セッション終了時の幅）
                }
                if let title = columnTitles[columnIds[i]]{
                    columnObject.title = title  //列のタイトルを設定する
                }
                tempArray.append(columnObject)  //一時配列に格納・順序は前回セッション終了時と同じ
            }
        }
        //TableViewオブジェクトの列の削除
        for column in tableView.tableColumns{
            tableView.removeTableColumn(column)
        }
        //一時配列から並び替えた列オブジェクトを追加する
        for column in tempArray{
            tableView.addTableColumn(column)
        }
    }
    //--------------------------------------------------------------------------
    //検索方法の変更
    //--------------------------------------------------------------------------
    @objc private  func selectSeachMethod(_ sender: NSMenuItem){
        for item in seachMethodMenu.items{
            item.state = .off
        }
        seachMethodMenu.item(withTag: sender.tag)?.state = .on
        if let item = Method.init(rawValue: sender.tag){
            searchMgr.searchMethod = item
        }
    }
    //--------------------------------------------------------------------------
    //アプリケーションの変更
    //--------------------------------------------------------------------------
    @objc private  func selectApplication(_ sender: NSMenuItem){
        for item in applicationMenu.items{
            item.state = .off
        }
        applicationMenu.item(withTag: sender.tag)?.state = .on
        currentAppIndex = sender.tag
    }
    //--------------------------------------------------------------------------
    //大文字・小文字の区別の変更
    //--------------------------------------------------------------------------
    @objc private  func selectCaseInsentive(_ sender: NSMenuItem){
        for item in caseInsentiveMenu.items{
            item.state = .off
        }
        caseInsentiveMenu.item(withTag: sender.tag)?.state = .on
        searchMgr.caseInsensitive = sender.tag.boolValue
    }
    //--------------------------------------------------------------------------
    //テーブルビューのクリア
    //--------------------------------------------------------------------------
    @IBAction func clearTableView(_ sender: NSMenuItem){
        resultList.removeAll()
        tableView.reloadData()
        tableViewMgr.sortStatus = ("", false)
        tableViewMgr.sortedTitle()
        elapsField.stringValue = ""
        countField.stringValue = ""
    }
    
    //--------------------------------------------------------------------------
    //メニューの選択値（tag value）
    //--------------------------------------------------------------------------
    private func menuCurrentItem(_ menu: NSMenu) -> Int{
        for item in menu.items{
            if item.state == .on{
                return item.tag
            }
        }
        return 0
    }
    //--------------------------------------------------------------------------
    //メニューの選択値の設定（tag value）
    //--------------------------------------------------------------------------
    private func menuSetItem(_ menu: NSMenu, _ tag: Int){
        for i in 0..<menu.items.count{
            if menu.items[i].tag == tag{
                menu.items[i].state = .on
            }else{
                menu.items[i].state = .off
            }
        }
    }
}

