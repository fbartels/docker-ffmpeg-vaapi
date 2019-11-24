#!/bin/sh

input=$1
shift

file_name="${input#/path/to/video/}"
short_file_name="${file_name%.mkv}"
docker_input_path="/data/${file_name}"
output_file_name="${short_file_name}.mkv"
docker_output_path="/output/${output_file_name}"

echo $docker_input_path
echo $docker_output_path

docker run \
  --detach \
  --rm \
  --mount "type=bind,src=/path/to/video,dst=/data" \
  --mount "type=bind,src=/path/to/output,dst=/output" \
  --device /dev/dri:/dev/dri \
  fbartels/ffmpeg-vaapi \
  -init_hw_device vaapi=foo:/dev/dri/renderD128 \
  -hwaccel vaapi \
  -hwaccel_device foo \
  -hwaccel_output_format vaapi \
  -i "${docker_input_path}" \
  -f matroska \
  -filter_hw_device foo \
  -vf 'format=nv12|vaapi,hwupload' \
  -c:v h264_vaapi \
  -b:v 4000k \
  -maxrate 6000k \
  -bufsize 12000k \
  -g 50 \
  -c:a copy \
  -c:s copy \
  "${docker_output_path}"
