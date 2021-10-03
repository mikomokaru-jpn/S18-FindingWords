//---- UASearch.Mgrswift ----

import Cocoa
//結果レコード構造体
struct Result {
    var fullPath: String = ""           //ファイル名（フルパス）
    var folder: String = ""         //フォルダ名
    var file: String = ""           //ファイル名
    var count: Int = 0              //ヒット件数
    var size: UInt64 = 0            //ファイルサイズ（バイト）
}
class UASearchMgr: NSObject {
    //検索方法
    var searchMethod: Method = .RangeOf
    //大文字・小文字の区別
    var caseInsensitive: Bool = true
    //エラーメッセージダイアログ
    let alert = NSAlert()
    //--------------------------------------------------------------------------
    //検索
    //--------------------------------------------------------------------------
    func search(){
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        //検索語：空白で分割
        let keywordText = appDelegate.keywordField.stringValue
        let tempKeywords = keywordText.components(separatedBy:CharacterSet.whitespaces)
        let keywords = stringArraytrim(tempKeywords)
        if keywords.count == 0{
            alert.messageText = "キーワード未入力"
            alert.informativeText = ""
            alert.runModal()
            return
        }
        //検索条件 AND or OR
        var condition = Condition.AND //default AND
        if let cell = appDelegate.condMatrix.selectedCell() {
            if cell.tag == Condition.OR.rawValue{
                condition = Condition.OR
            }
        }
        //拡張子：空白で分割
        let extensionText = appDelegate.extensionField.stringValue
        let tempExtensions = extensionText.components(separatedBy:CharacterSet.whitespaces)
        let extensions = stringArraytrim(tempExtensions)
        //検索の実行
        var elaps: Double = 0
        let targetPath = appDelegate.pathNameField.stringValue
        //ファイル名格納リスト
        let fileNameArray = NSMutableArray.init()
        //ディレクトリ存在チェック
        if !FileManager.default.fileExists(atPath: targetPath){
            alert.messageText = "ディレクトリが存在しない"
            alert.informativeText = targetPath
            alert.runModal()
            return
        }
        //特定のディレクトリ下のファイル名を再帰的に取得する
        traverse(targetPath, fileNameArray)
        appDelegate.resultList.removeAll()         //結果リストのクリア
        let startDate = Date() //処理時間策定開始
        //ファイルを読み込み、キーワードにマッチする文字列を検索する
        var countOfTextFile = 0
        for file in fileNameArray{
            guard let filePath = file as? String else{
                alert.messageText = "型変換エラー"
                alert.informativeText = "let filePath = file as? String"
                alert.runModal()
                return
            }
            let url = URL.init(fileURLWithPath: filePath)
            //対象ファイル（拡張子）の判定
            //正規表現オブジェクト・拡張子による判定
            if extensions.count > 0{
                var pattern = ""
                for ext in extensions{
                    if pattern != ""{
                        pattern += "|"
                    }
                    pattern += "^" + ext.replacingOccurrences(of: "*", with: ".*") + "$"
                }
                let regex: NSRegularExpression
                do { regex = try NSRegularExpression(pattern: pattern,
                                                     options:[.caseInsensitive])
                }catch{
                    alert.messageText = "正規表現オブエクト作成エラー"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                    return
                }
                if !self.isTrgetFile(extent: url.pathExtension,
                                     regex: regex,
                                     exclusion: appDelegate.exclusion.state){
                    continue //抜ける
                }
            }
            var matchList = [NSRange]() //初期化
            //URLからUTIを求め、テキストファイルのみ処理対象とする。
            if let values = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
               let uti = values.typeIdentifier {
                if UTTypeConformsTo(uti as CFString, kUTTypeText){
                    //テキストファイルの読み込み
                    /*
                    let text:String
                    do{
                        text = try String(contentsOf: url)
                    }catch{
                        print(String(format:"%@ (Shift-JIS etc..)",
                                     error.localizedDescription))
                        continue
                    }
                    */
                    guard let text = try? String(contentsOf: url) else{
                        print(String(format:"%@ :The file couldn't open (Shift-JIS etc..)", url.path))
                        continue
                    }
                    //キーワードによる全文検索
                    countOfTextFile += 1
                    //拡張・String+Search を使用する
                    for i in 0..<keywords.count{
                        if self.searchMethod == .RangeOf{
                            //range(of:)
                            var mask: NSString.CompareOptions = []
                            if !caseInsensitive{
                                //大文字・小文字を区別しない
                                mask.insert(.caseInsensitive)
                            }
                            let list = text.nsRanges(of: keywords[i], options: mask)
                            if condition == Condition.AND && list.count == 0{
                                //AND検索
                                matchList.removeAll()
                                break
                            }
                            matchList += list
                        }else if self.searchMethod == .Regex{
                            //正規表現
                            var mask: NSRegularExpression.Options = []
                            if !caseInsensitive{
                                //大文字・小文字を区別しない
                                mask.insert(.caseInsensitive)
                            }
                            let list = text.searchReg(keyword: keywords[i], options: mask)
                            if condition == Condition.AND && list.count == 0{
                                //AND検索
                                matchList.removeAll()
                                break
                            }
                            matchList += list
                        }
                    }
                }
            }
            //検索でヒットした
            if matchList.count > 0{
                var result = Result.init()
                result.fullPath = url.path
                result.file = url.lastPathComponent
                let folder = url.deletingLastPathComponent().path
                result.folder = folder.replacingOccurrences(of: targetPath, with: "")
                result.count = matchList.count
                if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
                    let size = attr[FileAttributeKey.size] as? UInt64{
                    result.size = size
                }
                //結果レコードの追加
                appDelegate.resultList.append(result)
            }
        }
        let endDate = Date() //処理時間測定終了
        elaps = endDate.timeIntervalSince(startDate)
        appDelegate.countField.stringValue =
            String(format:"該当ファイル数 = %ld / %ld",
                   appDelegate.resultList.count, countOfTextFile)
        appDelegate.elapsField.stringValue = String(format:"処理時間： %.3f sec", elaps)
    }
    //--------------------------------------------------------------------------
    //ファイル拡張子による判定
    //--------------------------------------------------------------------------
    private func isTrgetFile(extent: String,
                             regex: NSRegularExpression,
                             exclusion: NSControl.StateValue) -> Bool{
        //マッチング
        let results = regex.matches(in: extent,
                                    options: [],
                                    range: NSRange(0..<extent.count))
        if exclusion == .off{
            //指定された拡張子をは対象とする
            if results.count > 0 {
                return true
            }
        }else{
            //指定された拡張子をは対象外とする
            if results.count == 0 {
                return true
            }
        }
        return false
    }
    //--------------------------------------------------------------------------
    //文字列の配列から長さゼロの文字列を除外する
    //--------------------------------------------------------------------------
    private func stringArraytrim(_ array: [String]) -> [String]{
        var newArray = [String]()
        for item in array{
            if item.count > 0{
                newArray.append(item)
            }
        }
        return newArray
    }
}
