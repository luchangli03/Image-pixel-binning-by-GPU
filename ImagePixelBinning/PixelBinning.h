#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#define ThreadsPerBlock				32 //Threads Per Block


class PixelBinning_TypeDef
{
public:
	unsigned short *h_Image;
	unsigned short *d_Image;

	int ImageWidth;
	int ImageHigh;

	unsigned short *h_oImage;
	unsigned short *d_oImage;

	int oImageWidth;
	int oImageHigh;

	void GetPixelBinnedImageForCPU(unsigned short *h_iImage, float CameraOffset, int XBin, int YBin, cudaStream_t cstream);
	void GetPixelBinnedImageForGPU(unsigned short *h_iImage, float CameraOffset, int XBin, int YBin, cudaStream_t cstream);

	void UpdateImgSize(int ImageWidth, int ImageHigh); // must be used after init

	void Init(int ImageWidth, int ImageHigh);
	void Deinit();

};

