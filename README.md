## macOS S18_FindingWords
## Full-text search traversing a specified directory
Confirmed operation: MacOS 10.14.6 / Xcode 11.3.1

It searches all text files under a specific folder, including subfolders, and displays a list of file names containing the search terms on the table view. A target folder could be specified by Open Panel.


<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords1.png" alt="findingWords1" title="findingWords1" width="400">

## Display items
Display file names that contains search terms in its text string. The items are the folder name, the file name, the number of search terms contained in the file, and the file size (number of bytes). Records can be sorted using each item as a key. Clicking on a column heading of the table view, the records are sorted by ascending or descending order that toggled.
You can open the file with editor or browser, if you select a record of the table view and double-click it.
Click list display button to output the data to a file and open it with the same application as above.
Output destination： ~/Documents/DirectoryTraverse.txt

## You can specify the following search conditions
### (1) Multiple search terms
AND search that AND oerator is true is all search terms are included in the file. And OR search that OR operator is true is at least one search term is included in the file.
