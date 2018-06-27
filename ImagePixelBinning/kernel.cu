
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <afx.h>

#include "tinytiffreader.h"
#include "tinytiffwriter.h"


#include "PixelBinning.h"
#include "ListFiles.h"


void WriteUint16TiffImage(CString wFileName, unsigned short *h_Image, int ImageWidth, int ImageHigh);



int main()
{
	CStdioFile FileToProc(L"filepath to proc.txt", CFile::modeRead);

	CStdioFile ParaFile(L"ParaFile.txt", CFile::modeRead);


	int ImageWidth = 2560;
	int ImageHigh = 2048;

	int PixelBin_X;
	int PixelBin_Y;
	float CameraOffset;

	CString CurParaStr;

	// read parameters
	ParaFile.ReadString(CurParaStr);
	PixelBin_X = _ttoi(CurParaStr);

	ParaFile.ReadString(CurParaStr);
	PixelBin_Y = _ttoi(CurParaStr);

	ParaFile.ReadString(CurParaStr);
	CameraOffset = _ttof(CurParaStr);

	printf("pixel bin: %d %d, offset:%f\n", PixelBin_X, PixelBin_Y, CameraOffset);

	// create GPU resource
	PixelBinning_TypeDef PixelBinning;
	PixelBinning.Init(ImageWidth, ImageHigh);

	cudaStream_t loc_stream1;
	cudaStreamCreate(&loc_stream1);

	//

	char pFilePath[1024];

	CString curPath;
	vector<wstring> ofiles;

	while (FileToProc.ReadString(curPath))
	{
		wprintf(L"curpath:%s\n", curPath);

		if (curPath.Right(1) != L"\\")curPath += L"\\";

		// get files in current dir
		GetFilesInDir(ofiles, curPath.GetBuffer(), L"*.tif");

		int BaseDirLength = curPath.GetLength();

		// create a new folder to store images
		CString oFilePath = curPath + "PixelBined Images\\";

		CreateDirectory(oFilePath, NULL);

		// for each dir
		for (int i = 0; i < ofiles.size(); i++)
		{
			// for each image, may have many images in it

//			wprintf(L"%s\n", ofiles[i].c_str());
			WideCharToMultiByte(CP_ACP, 0, ofiles[i].c_str(), -1, pFilePath, 1024, NULL, NULL);


			TinyTIFFReaderFile* tiffr = TinyTIFFReader_open(pFilePath);


			if (tiffr)
			{
				ImageWidth = TinyTIFFReader_getWidth(tiffr);
				ImageHigh = TinyTIFFReader_getHeight(tiffr);
				int FrameNum = TinyTIFFReader_countFrames(tiffr);
				//			printf("img inf:%d %d %d\n", ImageWidth, ImageHigh, FrameNum);

				PixelBinning.UpdateImgSize(ImageWidth, ImageHigh);

				if (FrameNum == 1)
				{
					TinyTIFFReader_getSampleData(tiffr, PixelBinning.h_Image, 0); // get image data


					PixelBinning.GetPixelBinnedImageForCPU(PixelBinning.h_Image, CameraOffset, PixelBin_X, PixelBin_Y, loc_stream1);

					CString wImgName = ofiles[i].c_str();
					wImgName = oFilePath + wImgName.Right(wImgName.GetLength() - BaseDirLength);

					wImgName.TrimRight(L".tif");
					wImgName.Format(L"%s_Bin%dx%d.tif", wImgName, PixelBin_X, PixelBin_Y);

					WriteUint16TiffImage(wImgName, PixelBinning.h_oImage, PixelBinning.oImageWidth, PixelBinning.oImageHigh);

				}
				else
				{
					for (int fcnt = 0; fcnt < FrameNum; fcnt++)
					{
						TinyTIFFReader_getSampleData(tiffr, PixelBinning.h_Image, 0); // get image data
						TinyTIFFReader_readNext(tiffr);

						PixelBinning.GetPixelBinnedImageForCPU(PixelBinning.h_Image, CameraOffset, PixelBin_X, PixelBin_Y, loc_stream1);

						CString wImgName = ofiles[i].c_str();
						wImgName = oFilePath + wImgName.Right(wImgName.GetLength() - BaseDirLength);

						wImgName.TrimRight(L".tif");
						wImgName.Format(L"%s_Bin_%dx%d_%d.tif", wImgName, PixelBin_X, PixelBin_Y, fcnt);

						WriteUint16TiffImage(wImgName, PixelBinning.h_oImage, PixelBinning.oImageWidth, PixelBinning.oImageHigh);

					}

				}
			}
			else
			{
				printf("read error\n");
			}
			TinyTIFFReader_close(tiffr);

		}

	}

	PixelBinning.Deinit();
	cudaStreamDestroy(loc_stream1);

	FileToProc.Close();
	ParaFile.Close();
}



void WriteUint16TiffImage(CString wFileName, unsigned short *h_Image, int ImageWidth, int ImageHigh)
{
	char SRImgFileName[1024];
	//		sprintf_s(SRImgFileName, "ReRendered sr image_%d-%dnm.tif", GroupCnt, (int)RenderingPixelSize);

	WideCharToMultiByte(CP_OEMCP, NULL, wFileName.GetBuffer(), -1, SRImgFileName, 1024, NULL, FALSE);

	TinyTIFFFile* tif = TinyTIFFWriter_open(SRImgFileName, sizeof(unsigned short) * 8, ImageWidth, ImageHigh); // 32 bit float image
	TinyTIFFWriter_writeImage(tif, h_Image);

	TinyTIFFWriter_close(tif);

}

