/**
 * @file lv_nuttx_entry.h
 *
 */

/*********************
 *      INCLUDES
 *********************/
#include "lv_nuttx_entry.h"

#if LV_USE_NUTTX

#include <time.h>
#include <nuttx/tls.h>
#include <syslog.h>

#include "../../../lvgl.h"

/*********************
 *      DEFINES
 *********************/

/**********************
 *      TYPEDEFS
 **********************/

/**********************
 *  STATIC PROTOTYPES
 **********************/

static uint32_t millis(void);
static void syslog_print(lv_log_level_t level, const char * buf);

/**********************
 *  STATIC VARIABLES
 **********************/

/**********************
 *      MACROS
 **********************/

/**********************
 *   GLOBAL FUNCTIONS
 **********************/

#if LV_ENABLE_GLOBAL_CUSTOM

static void lv_global_free(void * data)
{
    if(data) {
        free(data);
    }
}

lv_global_t * lv_global_default(void)
{
    static int index = -1;
    lv_global_t * data;

    if(index < 0) {
        index = task_tls_alloc(lv_global_free);
    }

    if(index >= 0) {
        data = (lv_global_t *)task_tls_get_value(index);
        if(data == NULL) {
            data = (lv_global_t *)calloc(1, sizeof(lv_global_t));
            task_tls_set_value(index, (uintptr_t)data);
        }
    }
    return data;
}
#endif

void lv_nuttx_dsc_init(lv_nuttx_dsc_t * dsc)
{
    lv_memzero(dsc, sizeof(lv_nuttx_dsc_t));
    dsc->fb_path = "/dev/fb0";
    dsc->input_path = "/dev/input0";
}

void lv_nuttx_init(const lv_nuttx_dsc_t * dsc, lv_nuttx_result_t * result)
{
    lv_log_register_print_cb(syslog_print);
    lv_tick_set_cb(millis);

#if !LV_USE_NUTTX_CUSTOM_INIT

    if(dsc && dsc->fb_path) {
        lv_display_t * disp = NULL;

#if LV_USE_NUTTX_LCD
        disp = lv_nuttx_lcd_create(dsc->fb_path);
#else
        disp = lv_nuttx_fbdev_create();
        if(lv_nuttx_fbdev_set_file(disp, dsc->fb_path) != 0) {
            lv_display_remove(disp);
            disp = NULL;
        }
#endif
        if(result) {
            result->disp = disp;
        }
    }

    if(dsc && dsc->input_path) {
#if LV_USE_NUTTX_TOUCHSCREEN
        lv_indev_t * indev = lv_nuttx_touchscreen_create(dsc->input_path);
        if(result) {
            result->indev = indev;
        }
#endif
    }

#else

    lv_nuttx_init_custom(dsc, result);
#endif
}

/**********************
 *   STATIC FUNCTIONS
 **********************/

static uint32_t millis(void)
{
    struct timespec ts;

    clock_gettime(CLOCK_MONOTONIC, &ts);
    uint32_t tick = ts.tv_sec * 1000 + ts.tv_nsec / 1000000;

    return tick;
}

static void syslog_print(lv_log_level_t level, const char * buf)
{
    static const int priority[_LV_LOG_LEVEL_NUM] = {
        LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERR, LOG_CRIT
    };

    syslog(priority[level], "[LVGL] %s", buf);
}

#endif /*LV_USE_NUTTX*/
