import Foundation
extension String {
    //キーワードによる検索１：range(of:)
    // String.range(of:)メソッドでテキスト検索を行い、結果をNSrangeオブジェクトに変換する
    func nsRanges(of searchString: String,
                  options mask: NSString.CompareOptions = [],
                  locale: Locale? = nil) -> [NSRange]{
        let ranges = self.ranges(of: searchString, options: mask, locale: locale)
        return ranges.map { nsRange(from: $0) }
    }
    private func ranges(of searchString: String,
                        options mask: NSString.CompareOptions = [],
                        locale: Locale? = nil) -> [Range<String.Index>]{
        var ranges: [Range<String.Index>] = []
        while let range = self.range(of: searchString,
                                     options: mask,
                                     range: (ranges.last?.upperBound ?? startIndex)
                                             ..< endIndex,
                                     locale: locale){
            ranges.append(range)
        }
        return ranges
    }
    private func nsRange(from range: Range<String.Index>) -> NSRange{
        return NSRange.init(range, in: self) //String の extention らしい
    }
    //キーワードによる検索２：正規表現
    func searchReg(keyword: String, options mask: NSRegularExpression.Options = []) -> [NSRange]{
        var matchList = [NSRange]()
        do{
            let regex = try NSRegularExpression(pattern: keyword, options: mask)
            //検索実行
            let results = regex.matches(in: self,
                                        options: [],
                                        range: NSRange(0..<self.count))
            for result in results {
                matchList.append(result.range)
            }
        }catch{
            print(error.localizedDescription)
            return matchList
        }
        return matchList
    }
}
