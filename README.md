# docker-ffmpeg-vaapi
This repository contains a docker image for FFmpeg with VAAPI. 
**Recommended**: Use 3.x kernel. This image might not work on the newer kernel.

## Included Libraries
The build currently includes the below libraries. If more are needed, follow the format to add an additional library.
 - libx264
 - libx265
 - vaapi
 - libbluray
 - libfdk_aac
 - libvpx

## Install
Pull the image from the docker registry.

```shell
docker pull pocka/ffmpeg-vaapi
```

## Example
This example shows you the case:
Convert MPEG2-TS(`input.ts`) to MP4(H.264)(`output.mp4`) and scale it to 1280x720.

```shell
docker run \
  --privileged \
  -v /dev/dri:/dev/dri \
  -v `pwd`:/data \
  pocka/ffmpeg-vaapi \
    -vaapi_device /dev/dri/renderD128 \
    -hwaccel vaapi \
    -hwaccel_output_format vaapi \
    -i input.ts \
    -vf 'format=nv12|vaapi,hwupload,scale_vaapi=w=1280:h=720' \
    -c:v h264_vaapi \
    output.mp4
```

For more detail of VAAPI option, see [Livav's document](https://wiki.libav.org/Hardware/vaapi).
