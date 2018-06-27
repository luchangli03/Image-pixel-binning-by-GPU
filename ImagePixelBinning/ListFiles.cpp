#include "ListFiles.h"


void GetFilesInDir(vector<wstring> &ofiles, wstring DirPath, wstring PostFix)
{
	HANDLE hFind;
	WIN32_FIND_DATA data;

	ofiles.clear();

	wstring SearchName = DirPath + PostFix;


	hFind = FindFirstFile(SearchName.c_str(), &data);
	if (hFind != INVALID_HANDLE_VALUE) {
		do {
			// add the path and file name together
			ofiles.push_back(DirPath + data.cFileName);

		} while (FindNextFile(hFind, &data));
		FindClose(hFind);
	}

}
