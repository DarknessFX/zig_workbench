/**
 * @file lv_libpng.c
 *
 */

/*********************
 *      INCLUDES
 *********************/
#include "../../../lvgl.h"
#if LV_USE_LIBPNG

#include "lv_libpng.h"
#include <png.h>

/*********************
 *      DEFINES
 *********************/

/**********************
 *      TYPEDEFS
 **********************/

/**********************
 *  STATIC PROTOTYPES
 **********************/
static lv_result_t decoder_info(lv_image_decoder_t * decoder, const void * src, lv_image_header_t * header);
static lv_result_t decoder_open(lv_image_decoder_t * decoder, lv_image_decoder_dsc_t * dsc);
static void decoder_close(lv_image_decoder_t * decoder, lv_image_decoder_dsc_t * dsc);
static const void * decode_png_file(const char * filename);
static lv_result_t try_cache(lv_image_decoder_dsc_t * dsc);

/**********************
 *  STATIC VARIABLES
 **********************/

/**********************
 *      MACROS
 **********************/

/**********************
 *   GLOBAL FUNCTIONS
 **********************/

/**
 * Register the PNG decoder functions in LVGL
 */
void lv_libpng_init(void)
{
    lv_image_decoder_t * dec = lv_image_decoder_create();
    lv_image_decoder_set_info_cb(dec, decoder_info);
    lv_image_decoder_set_open_cb(dec, decoder_open);
    lv_image_decoder_set_close_cb(dec, decoder_close);
}

void lv_libpng_deinit(void)
{
    lv_image_decoder_t * dec = NULL;
    while((dec = lv_image_decoder_get_next(dec)) != NULL) {
        if(dec->info_cb == decoder_info) {
            lv_image_decoder_delete(dec);
            break;
        }
    }
}

/**********************
 *   STATIC FUNCTIONS
 **********************/

/**
 * Get info about a PNG image
 * @param src can be file name or pointer to a C array
 * @param header store the info here
 * @return LV_RESULT_OK: no error; LV_RESULT_INVALID: can't get the info
 */
static lv_result_t decoder_info(lv_image_decoder_t * decoder, const void * src, lv_image_header_t * header)
{
    LV_UNUSED(decoder); /*Unused*/
    lv_image_src_t src_type = lv_image_src_get_type(src);          /*Get the source type*/

    /*If it's a PNG file...*/
    if(src_type == LV_IMAGE_SRC_FILE) {
        const char * fn = src;

        lv_fs_file_t f;
        lv_fs_res_t res = lv_fs_open(&f, fn, LV_FS_MODE_RD);
        if(res != LV_FS_RES_OK) return LV_RESULT_INVALID;

        /* Read the width and height from the file. They have a constant location:
         * [16..19]: width
         * [20..23]: height
         */
        uint8_t buf[24];
        uint32_t rn;
        lv_fs_read(&f, buf, sizeof(buf), &rn);
        lv_fs_close(&f);

        if(rn != sizeof(buf)) return LV_RESULT_INVALID;

        const uint8_t magic[] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
        if(memcmp(buf, magic, sizeof(magic)) != 0) return LV_RESULT_INVALID;

        uint32_t * size = (uint32_t *)&buf[16];
        /*Save the data in the header*/
        header->always_zero = 0;
        header->cf = LV_COLOR_FORMAT_ARGB8888;
        /*The width and height are stored in Big endian format so convert them to little endian*/
        header->w = (int32_t)((size[0] & 0xff000000) >> 24) + ((size[0] & 0x00ff0000) >> 8);
        header->h = (int32_t)((size[1] & 0xff000000) >> 24) + ((size[1] & 0x00ff0000) >> 8);

        return LV_RESULT_OK;
    }

    return LV_RESULT_INVALID;         /*If didn't succeeded earlier then it's an error*/
}


/**
 * Open a PNG image and return the decided image
 * @param src can be file name or pointer to a C array
 * @param style style of the image object (unused now but certain formats might use it)
 * @return pointer to the decoded image or  `LV_IMAGE_DECODER_OPEN_FAIL` if failed
 */
static lv_result_t decoder_open(lv_image_decoder_t * decoder, lv_image_decoder_dsc_t * dsc)
{
    LV_UNUSED(decoder); /*Unused*/

    /*Check the cache first*/
    if(try_cache(dsc) == LV_RESULT_OK) return LV_RESULT_OK;

    /*If it's a PNG file...*/
    if(dsc->src_type == LV_IMAGE_SRC_FILE) {
        const char * fn = dsc->src;
        lv_cache_lock();
        lv_cache_entry_t * cache = lv_cache_add(dsc->header.w * dsc->header.h * sizeof(uint32_t));
        if(cache == NULL) {
            lv_cache_unlock();
            return LV_RESULT_INVALID;
        }

        uint32_t t = lv_tick_get();
        const void * decoded_img = decode_png_file(fn);
        t = lv_tick_elaps(t);
        cache->weight = t;
        cache->data = decoded_img;
        cache->free_data = 1;
        if(dsc->src_type == LV_IMAGE_SRC_FILE) {
            cache->src = lv_strdup(dsc->src);
            cache->src_type = LV_CACHE_SRC_TYPE_STR;
            cache->free_src = 1;
        }
        else {
            cache->src_type = LV_CACHE_SRC_TYPE_PTR;
            cache->src = dsc->src;
        }

        dsc->img_data = lv_cache_get_data(cache);
        dsc->cache_entry = cache;

        lv_cache_unlock();
        return LV_RESULT_OK;     /*The image is fully decoded. Return with its pointer*/
    }

    return LV_RESULT_INVALID;    /*If not returned earlier then it failed*/
}

/**
 * Free the allocated resources
 */
static void decoder_close(lv_image_decoder_t * decoder, lv_image_decoder_dsc_t * dsc)
{
    LV_UNUSED(decoder); /*Unused*/

    lv_cache_lock();
    lv_cache_release(dsc->cache_entry);
    lv_cache_unlock();
}

static lv_result_t try_cache(lv_image_decoder_dsc_t * dsc)
{
    lv_cache_lock();
    if(dsc->src_type == LV_IMAGE_SRC_FILE) {
        const char * fn = dsc->src;

        lv_cache_entry_t * cache = lv_cache_find(fn, LV_CACHE_SRC_TYPE_STR, 0, 0);
        if(cache) {
            dsc->img_data = lv_cache_get_data(cache);
            dsc->cache_entry = cache;     /*Save the cache to release it in decoder_close*/
            lv_cache_unlock();
            return LV_RESULT_OK;
        }
    }

    lv_cache_unlock();
    return LV_RESULT_INVALID;
}

static uint8_t * alloc_file(const char * filename, uint32_t * size)
{
    uint8_t * data = NULL;
    lv_fs_file_t f;
    uint32_t data_size;
    uint32_t rn;
    lv_fs_res_t res;

    *size = 0;

    res = lv_fs_open(&f, filename, LV_FS_MODE_RD);
    if(res != LV_FS_RES_OK) {
        LV_LOG_WARN("can't open %s", filename);
        return NULL;
    }

    res = lv_fs_seek(&f, 0, LV_FS_SEEK_END);
    if(res != LV_FS_RES_OK) {
        goto failed;
    }

    res = lv_fs_tell(&f, &data_size);
    if(res != LV_FS_RES_OK) {
        goto failed;
    }

    res = lv_fs_seek(&f, 0, LV_FS_SEEK_SET);
    if(res != LV_FS_RES_OK) {
        goto failed;
    }

    /*Read file to buffer*/
    data = lv_malloc(data_size);
    if(data == NULL) {
        LV_LOG_WARN("malloc failed for data");
        goto failed;
    }

    res = lv_fs_read(&f, data, data_size, &rn);

    if(res == LV_FS_RES_OK && rn == data_size) {
        *size = rn;
    }
    else {
        LV_LOG_WARN("read file failed");
        lv_free(data);
        data = NULL;
    }

failed:
    lv_fs_close(&f);

    return data;
}

static const void * decode_png_file(const char * filename)
{
    int ret;

    /*Prepare png_image*/
    png_image image;
    lv_memzero(&image, sizeof(image));
    image.version = PNG_IMAGE_VERSION;

    uint32_t data_size;
    uint8_t * data = alloc_file(filename, &data_size);
    if(data == NULL) {
        LV_LOG_WARN("can't load file: %s", filename);
        return NULL;
    }

    /*Ready to read file*/
    ret = png_image_begin_read_from_memory(&image, data, data_size);
    if(!ret) {
        LV_LOG_ERROR("png file: %s read failed: %d", filename, ret);
        lv_free(data);
        return NULL;
    }

    /*Set color format*/
    image.format = PNG_FORMAT_BGRA;

    /*Alloc image buffer*/
    size_t image_size = PNG_IMAGE_SIZE(image);
    void * image_data = lv_draw_buf_malloc(image_size, LV_COLOR_FORMAT_ARGB8888);

    if(image_data) {
        /*Start decoding*/
        ret = png_image_finish_read(&image, NULL, image_data, 0, NULL);
        if(!ret) {
            LV_LOG_ERROR("png decode failed: %d", ret);
            lv_draw_buf_free(image_data);
            image_data = NULL;
        }
    }
    else {
        LV_LOG_ERROR("png alloc %zu failed", image_size);
    }

    /*free decoder*/
    png_image_free(&image);
    lv_free(data);

    return image_data;
}

#endif /*LV_USE_LIBPNG*/
