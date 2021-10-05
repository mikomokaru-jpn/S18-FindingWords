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

### You can specify the following search conditions
### (1) Multiple search terms
AND search that AND oerator is true is all search terms are included in the file. And OR search that OR operator is true is at least one search term is included in the file.

<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords5.png" alt="findingWords5" title="findingWords5" width="380">

### (2) Limitting files to be searched by a extention
You can limmit the files to be searched by specifying a file extension that could be with a wild card (*). Also you can enter multiple extensions. If the exclusion check box is on, on the contrary, files with the specified extension will not be searched.

<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords6.png" alt="findingWords6" title="findingWords6" width="310">

### (3) Specifying the search method
You can select either range (of :) method of String class or regular expression object as the search method. The former does not support regular expression function.

<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords2.png" alt="findingWords2" title="findingWords2" width="300">

### (4) Case sensitive
You can choose to be Case sensitive or not.

<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords4.png" alt="findingWords4" title="findingWords4" width="300">

### Select the application to open file
You can select an application from the menu.

<img src="http://mikomokaru.sakura.ne.jp/data/B40/findingWords3.png" alt="findingWords3" title="findingWords3" width="300">

### Save the current state and options
The size of the window, the width of the columns in the table view, and the order of the columns are saved in User Default when the application is ended. Selection values of menus which are search method, application for opening file, and case sensitive are also saved. These changes made by a user is carried over to the next time when the application starts.




