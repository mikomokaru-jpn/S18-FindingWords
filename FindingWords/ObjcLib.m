#import "ObjcLib.h"
#include <dirent.h>   //ディレクトリ内のファイルリストを得る（POSIX）
//#include <sys/stat.h> //ファイル・ディレクトリに関する情報を取得（POSIX）
@implementation ObjcLib
//------------------------------------------------------------------------------
//特定のディレクトリ下のファイル名を再帰的に取得する
//------------------------------------------------------------------------------
void traverse(const char* directory, NSMutableArray* array) {
    DIR* dir = opendir(directory);   //検索ディレクトリをオープンする
    
    if (dir == nil){
        return;
    }
    struct dirent* entry;            //ノード（ファイルorディレクトリ）情報
    char newPath[4096];              //パス名の格納バッファ [最大長4096バイト]
    if (dir) {
        for(;;) {
            if ((entry = readdir(dir)) == NULL) { //ノードを読み込む
                break;
            }
            //パス名の編集
            strcpy(newPath, directory);     //検索ディレクトリ名
            strcat(newPath, "/");
            strcat(newPath, entry->d_name); //ノード名（ファイルorディレクトリ）
            NSString* strPath = [NSString stringWithCString:newPath
                                                   encoding:NSUTF8StringEncoding];
            if (entry->d_type == DT_DIR) {  //種別の判定
                //ディレクトの場合
                if (strcmp(entry->d_name, ".")==0 || strcmp(entry->d_name, "..")==0) {
                    //カレントディレクトリ(.)、親ディレクトリ(..)はスキップ
                }else {
                    //ディレクトリなら自身を呼び出す（再帰）
                    traverse(newPath, array);
                }
            } else {
                //ファイルの場合、ファイル名配列に格納
                [array addObject:strPath];
            }
        }
    }
    closedir(dir);  //ディレクトリをクローズする
}
@end
