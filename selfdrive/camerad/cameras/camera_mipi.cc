#include "selfdrive/camerad/cameras/camera_mipi.h"

#include <assert.h>
#include <string.h>
#include <unistd.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundefined-inline"
#include <opencv2/core.hpp>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui.hpp>
#pragma clang diagnostic pop

#include "selfdrive/common/clutil.h"
#include "selfdrive/common/swaglog.h"
#include "selfdrive/common/timing.h"
#include "selfdrive/common/util.h"

#define FRAME_WIDTH  1164
#define FRAME_HEIGHT 874

extern ExitHandler do_exit;

namespace {

CameraInfo cameras_supported[CAMERA_ID_MAX] = {
  // road facing
  [CAMERA_ID_IMX477] = {
      .frame_width = FRAME_WIDTH,
      .frame_height = FRAME_HEIGHT,
      .frame_stride = FRAME_WIDTH*3,
      .bayer = false,
      .bayer_flip = false,
  },
};
std::string gstreamer_pipeline(int sensor_mode, int sensor_id, int flip_method, int display_width, int display_height) {
    // sensor mode 1 = 1920 x 1080
    return "nvarguscamerasrc sensor_mode=" + std::to_string(sensor_mode) +
           " sensor_id=" + std::to_string(sensor_id) +
           " ! video/x-raw(memory:NVMM)" +
           ", format=(string)NV12" +
           ", framerate=(fraction)20/1" +
           ", width=(int)" + std::to_string(display_width) +
           ", height=(int)" + std::to_string(display_height) +
           " ! nvvidconv flip-method=" + std::to_string(flip_method) +
           " ! video/x-raw, format=BGRx" +
           " ! videoconvert ! video/x-raw, format=(string)BGR" +
           " ! appsink";
}
void camera_open(CameraState *s, bool rear) {
  // empty
}

void camera_close(CameraState *s) {
  // empty
}

void camera_init(VisionIpcServer * v, CameraState *s, int camera_id, unsigned int fps, cl_device_id device_id, cl_context ctx, VisionStreamType rgb_type, VisionStreamType yuv_type) {
  assert(camera_id < std::size(cameras_supported));
  s->ci = cameras_supported[camera_id];
  assert(s->ci.frame_width != 0);

  s->camera_num = camera_id;
  s->fps = fps;
  s->buf.init(device_id, ctx, s, v, FRAME_BUF_COUNT, rgb_type, yuv_type);
}

void run_camera(CameraState *s, cv::VideoCapture &video_cap, float *ts) {
  assert(video_cap.isOpened());

  cv::Size size(s->ci.frame_width, s->ci.frame_height);
  const cv::Mat transform = cv::Mat(3, 3, CV_32F, ts);
  uint32_t frame_id = 0;
  size_t buf_idx = 0;

  while (!do_exit) {
    cv::Mat frame_mat, transformed_mat;
    video_cap >> frame_mat;
    cv::warpPerspective(frame_mat, transformed_mat, transform, size, cv::INTER_LINEAR, cv::BORDER_CONSTANT, 0);

    s->buf.camera_bufs_metadata[buf_idx] = {.frame_id = frame_id};

    auto &buf = s->buf.camera_bufs[buf_idx];
    int transformed_size = transformed_mat.total() * transformed_mat.elemSize();
    CL_CHECK(clEnqueueWriteBuffer(buf.copy_q, buf.buf_cl, CL_TRUE, 0, transformed_size, transformed_mat.data, 0, NULL, NULL));

    s->buf.queue(buf_idx);

    ++frame_id;
    buf_idx = (buf_idx + 1) % FRAME_BUF_COUNT;
  }
}

static void road_camera_thread(CameraState *s) {
  set_thread_name("mipi_road_camera_thread");

  std::string pipeline = gstreamer_pipeline(
    1, // sensor mode
    0, // sensor id
    2, // flip method
    864, // width
    486); // height

  cv::VideoCapture cap_road(pipeline, cv::CAP_GSTREAMER); // road
  float ts[9] = {1.50330396, 0.0, -59.40969163,
                  0.0, 1.50330396, 76.20704846,
                  0.0, 0.0, 1.0};
  run_camera(s, cap_road, ts);
}

}  // namespace

void cameras_init(VisionIpcServer *v, MultiCameraState *s, cl_device_id device_id, cl_context ctx) {
  camera_init(v, &s->road_cam, CAMERA_ID_IMX477, 20, device_id, ctx,
              VISION_STREAM_RGB_BACK, VISION_STREAM_YUV_BACK);
  s->pm = new PubMaster({"roadCameraState", "thumbnail"});
}

void camera_autoexposure(CameraState *s, float grey_frac) {}

void cameras_open(MultiCameraState *s) {
  camera_open(&s->road_cam, true);
}

void cameras_close(MultiCameraState *s) {
  camera_close(&s->road_cam);
  delete s->pm;
}

void process_road_camera(MultiCameraState *s, CameraState *c, int cnt) {
  const CameraBuf *b = &c->buf;
  MessageBuilder msg;
  auto framed = msg.initEvent().initRoadCameraState();
  fill_frame_data(framed, b->cur_frame_data);
  framed.setImage(kj::arrayPtr((const uint8_t *)b->cur_yuv_buf->addr, b->cur_yuv_buf->len));
  framed.setTransform(b->yuv_transform.v);
  s->pm->send("roadCameraState", msg);
}

void cameras_run(MultiCameraState *s) {
  std::vector<std::thread> threads;
  threads.push_back(start_process_thread(s, &s->road_cam, process_road_camera));

  std::thread t_rear = std::thread(road_camera_thread, &s->road_cam);
  set_thread_name("mipi_thread");

  t_rear.join();

  for (auto &t : threads) t.join();

  cameras_close(s);
}
