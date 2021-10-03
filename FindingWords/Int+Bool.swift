import Foundation
//Int拡張・値に応じたBool値を返す
extension Int {
    var boolValue: Bool { return self != 0 }
}
//Bool拡張・値に応じたInt値を返す
extension Bool {
    var intValue: Int{
        if self{
            return 1
        }else{
            return 0
        }
    }
}
