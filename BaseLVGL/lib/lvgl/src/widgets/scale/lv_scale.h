/**
 * @file lv_scale.h
 *
 */

#ifndef LV_SCALE_H
#define LV_SCALE_H

#ifdef __cplusplus
extern "C" {
#endif

/*********************
 *      INCLUDES
 *********************/
#include "../../lv_conf_internal.h"

#if LV_USE_SCALE != 0

#include "../../core/lv_obj.h"

/*********************
 *      DEFINES
 *********************/

/**Default value of total minor ticks. */
#define LV_SCALE_TOTAL_TICK_COUNT_DEFAULT (11U)
LV_EXPORT_CONST_INT(LV_SCALE_TOTAL_TICK_COUNT_DEFAULT);

/**Default value of major tick every nth ticks. */
#define LV_SCALE_MAJOR_TICK_EVERY_DEFAULT (5U)
LV_EXPORT_CONST_INT(LV_SCALE_MAJOR_TICK_EVERY_DEFAULT);

/**Default value of scale label enabled. */
#define LV_SCALE_LABEL_ENABLED_DEFAULT (1U)
LV_EXPORT_CONST_INT(LV_SCALE_LABEL_ENABLED_DEFAULT);

/**********************
 *      TYPEDEFS
 **********************/

/**
 * Scale mode
 */
enum {
    LV_SCALE_MODE_HORIZONTAL_TOP    = 0x00U,
    LV_SCALE_MODE_HORIZONTAL_BOTTOM = 0x01U,
    LV_SCALE_MODE_VERTICAL_LEFT     = 0x02U,
    LV_SCALE_MODE_VERTICAL_RIGHT    = 0x04U,
    LV_SCALE_MODE_ROUND_INNER       = 0x08U,
    LV_SCALE_MODE_ROUND_OUTER      = 0x10U,
    _LV_SCALE_MODE_LAST
};
typedef uint32_t lv_scale_mode_t;

typedef struct {
    lv_style_t * main_style;
    lv_style_t * indicator_style;
    lv_style_t * items_style;
    int32_t minor_range;
    int32_t major_range;
    uint32_t first_tick_idx_in_section;
    uint32_t last_tick_idx_in_section;
    uint32_t first_tick_idx_is_major;
    uint32_t last_tick_idx_is_major;
    int32_t first_tick_in_section_width;
    int32_t last_tick_in_section_width;
    lv_point_t first_tick_in_section;
    lv_point_t last_tick_in_section;
} lv_scale_section_t;

typedef struct {
    lv_obj_t obj;
    lv_ll_t section_ll;     /**< Linked list for the sections (stores lv_scale_section_t)*/
    const char ** txt_src;
    int32_t custom_label_cnt;
    int32_t major_len;
    int32_t minor_len;
    int32_t range_min;
    int32_t range_max;
    uint32_t total_tick_count   : 15;
    uint32_t major_tick_every   : 15;
    lv_scale_mode_t mode;
    uint32_t label_enabled      : 1;
    uint32_t post_draw      : 1;
    int32_t last_tick_width;
    int32_t first_tick_width;
    /* Round scale */
    uint32_t angle_range;
    int32_t rotation;
} lv_scale_t;

extern const lv_obj_class_t lv_scale_class;

/**********************
 * GLOBAL PROTOTYPES
 **********************/

/**
 * Create an scale object
 * @param parent pointer to an object, it will be the parent of the new scale
 * @return pointer to the created scale
 */
lv_obj_t * lv_scale_create(lv_obj_t * parent);

/*======================
 * Add/remove functions
 *=====================*/

/*=====================
 * Setter functions
 *====================*/

/**
 * Set scale mode. See @ref lv_scale_mode_t
 * @param   obj     pointer the scale object
 * @param   mode    New scale mode
 */
void lv_scale_set_mode(lv_obj_t * obj, lv_scale_mode_t mode);

/**
 * Set scale total tick count (including minor and major ticks)
 * @param   obj       pointer the scale object
 * @param   total_tick_count    New total tick count
 */
void lv_scale_set_total_tick_count(lv_obj_t * obj, int32_t total_tick_count);

/**
 * Sets how often the major tick will be drawn
 * @param   obj       pointer the scale object
 * @param   major_tick_every    New count for major tick drawing
 */
void lv_scale_set_major_tick_every(lv_obj_t * obj, int32_t major_tick_every);

/**
 * Sets label visibility
 * @param   obj       pointer the scale object
 * @param   show_label  Show axis label
 */
void lv_scale_set_label_show(lv_obj_t * obj, bool show_label);

/**
 * Sets major tick length
 * @param   obj       pointer the scale object
 * @param   major_len   Major tick length
 */
void lv_scale_set_major_tick_length(lv_obj_t * obj, int32_t major_len);

/**
 * Sets major tick length
 * @param   obj       pointer the scale object
 * @param   minor_len   Minor tick length
 */
void lv_scale_set_minor_tick_length(lv_obj_t * obj, int32_t minor_len);

/**
 * Set the minimal and maximal values on a scale
 * @param obj       pointer to a scale object
 * @param min       minimum value of the scale
 * @param max       maximum value of the scale
 */
void lv_scale_set_range(lv_obj_t * obj, int32_t min, int32_t max);

/**
 * Set properties specific to round scale
 * @param obj       pointer to a scale object
 * @param angle_range   the angular range of the scale
 * @param rotation  the angular offset from the 3 o'clock position (clock-wise)
 */
void lv_scale_set_round_props(lv_obj_t * obj, uint32_t angle_range, int32_t rotation);

/**
 * Set custom text source for major ticks labels
 * @param obj       pointer to a scale object
 * @param txt_src   pointer to an array of strings which will be display at major ticks
 */
void lv_scale_set_text_src(lv_obj_t * obj, const char * txt_src[]);

/**
 * Draw the scale after all the children are drawn
 * @param obj       pointer to a scale object
 * @param en        true: enable post draw
 */
void lv_scale_set_post_draw(lv_obj_t * obj, bool en);

/**
 * Add a section to the given scale
 * @param obj       pointer to a scale object
 * @return          pointer to the new section
 */
lv_scale_section_t * lv_scale_add_section(lv_obj_t * obj);

/**
 * Set the range for the given scale section
 * @param obj       pointer to a scale section object
 * @param minor_range   section new minor range
 * @param major_range   section new major range
 */
void lv_scale_section_set_range(lv_scale_section_t * section, int32_t minor_range, int32_t major_range);

/**
 * Set the style of the part for the given scale section
 * @param obj       pointer to a scale section object
 * @param part      Section part
 * @param section_part_style Pointer to the section part style
 */
void lv_scale_section_set_style(lv_scale_section_t * section, uint32_t part, lv_style_t * section_part_style);

/*=====================
 * Getter functions
 *====================*/

/**********************
 *      MACROS
 **********************/

#endif /*LV_USE_SCALE*/

#ifdef __cplusplus
} /*extern "C"*/
#endif

#endif /*LV_SCALE_H*/
