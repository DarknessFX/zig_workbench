﻿/**
 * @file win32drv.h
 *
 */

#ifndef LV_WIN32DRV_H
#define LV_WIN32DRV_H

/*********************
 *      INCLUDES
 *********************/

#include "../lvgl/lvgl.h"
#include "../lvgl/src/display/lv_display.h"
#include "../lvgl/src/misc/lv_color.h"

#include <windows.h>

#if _MSC_VER >= 1200
 // Disable compilation warnings.
#pragma warning(push)
// nonstandard extension used : bit field types other than int
#pragma warning(disable:4214)
// 'conversion' conversion from 'type1' to 'type2', possible loss of data
#pragma warning(disable:4244)
#endif

#ifdef LV_LVGL_H_INCLUDE_SIMPLE
#include "lvgl.h"
#else
#include "../lvgl/lvgl.h"
#endif

#if _MSC_VER >= 1200
// Restore compilation warnings.
#pragma warning(pop)
#endif

/*********************
 *      DEFINES
 *********************/

#define LVGL_SIMULATOR_WINDOW_CLASS L"BaseLVGL"

/**********************
 *      TYPEDEFS
 **********************/

typedef struct _lv_win32_keyboard_queue_item_t
{
    SLIST_ENTRY ItemEntry;
    uint32_t key;
    lv_indev_state_t state;
} lv_win32_keyboard_queue_item_t;

typedef struct _lv_win32_window_context_t
{
    lv_disp_t* display_device_object;
    lv_indev_t* mouse_device_object;
    lv_indev_t* mousewheel_device_object;
    lv_indev_t* keyboard_device_object;

    int32_t display_hor_res;
    int32_t display_ver_res;
    uint32_t display_dpi;
    void* display_draw_buffer_base;
    size_t display_draw_buffer_size;
    volatile bool display_refreshing;
    HDC display_framebuffer_context_handle;
    uint32_t* display_framebuffer_base;
    size_t display_framebuffer_size;

    lv_indev_state_t mouse_state;
    lv_point_t mouse_point;

    lv_indev_state_t mousewheel_state;
    int16_t mousewheel_enc_diff;

    CRITICAL_SECTION keyboard_mutex;
    PSLIST_HEADER keyboard_queue;
    uint16_t keyboard_utf16_high_surrogate;
    uint16_t keyboard_utf16_low_surrogate;
} lv_win32_window_context_t;

/**********************
 * GLOBAL PROTOTYPES
 **********************/

EXTERN_C bool lv_win32_quit_signal;

EXTERN_C lv_indev_t* lv_win32_pointer_device_object;
EXTERN_C lv_indev_t* lv_win32_keypad_device_object;
EXTERN_C lv_indev_t* lv_win32_encoder_device_object;

EXTERN_C void lv_win32_add_all_input_devices_to_group(
    lv_group_t* group);

EXTERN_C lv_win32_window_context_t* lv_win32_get_window_context(
    HWND window_handle);

EXTERN_C bool lv_win32_init_window_class();

EXTERN_C HWND lv_win32_create_display_window(
    const wchar_t* window_title,
    int32_t hor_res,
    int32_t ver_res,
    HINSTANCE instance_handle,
    HICON icon_handle,
    int show_window_mode);

EXTERN_C bool lv_win32_init(
    HINSTANCE instance_handle,
    int show_window_mode,
    int32_t hor_res,
    int32_t ver_res,
    HICON icon_handle);

/**********************
 *      MACROS
 **********************/

#endif /*LV_WIN32DRV_H*/
