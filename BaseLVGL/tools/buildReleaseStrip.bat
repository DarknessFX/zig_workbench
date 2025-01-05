@ECHO OFF
CD ..

REM EXTRA ARGS SHORTCUT
REM ===================
REM  Linking system libraries (note: -l and library name all together):
REM   -lSDL2 -lOpenGL32
REM  Adding libraries DLL+LIB folders (note: -L SPACE Folder path):
REM   -L %CD%\lib\SDL2 
REM  Adding cImport .H include folders (note: -I SPACE Folder path):
REM    -I %CD%\lib\microui -I %CD%\lib\SDL2\include
REM
REM Full extra_args sample of a project that use SDL2 + OpenGL + microui :
REM  SET extra_args=-lSDL2 -lOpenGL32 -L "%CD%\lib\SDL2" -I "%CD%\lib\microui" -I "%CD%\lib\SDL2\include"

SET extra_args=-lGDI32 -I"%CD%" -Ilib\lvgl -Ilib\lvgl_drv -cflags -Wno-implicit-function-declaration -- lib/lvgl/src/lv_init.c lib/lvgl/src/core/lv_group.c lib/lvgl/src/core/lv_obj_class.c lib/lvgl/src/core/lv_obj_draw.c lib/lvgl/src/core/lv_obj_event.c lib/lvgl/src/core/lv_obj_id_builtin.c lib/lvgl/src/core/lv_obj_pos.c lib/lvgl/src/core/lv_obj_property.c lib/lvgl/src/core/lv_obj_scroll.c lib/lvgl/src/core/lv_obj_style.c lib/lvgl/src/core/lv_obj_style_gen.c lib/lvgl/src/core/lv_obj_tree.c lib/lvgl/src/core/lv_obj.c lib/lvgl/src/core/lv_refr.c lib/lvgl/src/indev/lv_indev.c lib/lvgl/src/indev/lv_indev_scroll.c lib/lvgl/src/stdlib/lv_mem.c lib/lvgl/src/stdlib/builtin/lv_mem_core_builtin.c lib/lvgl/src/stdlib/builtin/lv_string_builtin.c lib/lvgl/src/stdlib/builtin/lv_sprintf_builtin.c lib/lvgl/src/stdlib/builtin/lv_tlsf.c lib/lvgl/src/misc/lv_anim.c lib/lvgl/src/misc/lv_anim_timeline.c lib/lvgl/src/misc/lv_area.c lib/lvgl/src/misc/lv_async.c lib/lvgl/src/misc/lv_bidi.c lib/lvgl/src/misc/lv_cache.c lib/lvgl/src/misc/lv_cache_builtin.c lib/lvgl/src/misc/lv_color.c lib/lvgl/src/misc/lv_color_op.c lib/lvgl/src/misc/lv_event.c lib/lvgl/src/misc/lv_fs.c lib/lvgl/src/misc/lv_ll.c lib/lvgl/src/misc/lv_log.c lib/lvgl/src/misc/lv_lru.c lib/lvgl/src/misc/lv_math.c lib/lvgl/src/misc/lv_palette.c lib/lvgl/src/misc/lv_profiler_builtin.c lib/lvgl/src/misc/lv_style.c lib/lvgl/src/misc/lv_style_gen.c lib/lvgl/src/misc/lv_templ.c lib/lvgl/src/misc/lv_text.c lib/lvgl/src/misc/lv_text_ap.c lib/lvgl/src/misc/lv_timer.c lib/lvgl/src/misc/lv_utils.c lib/lvgl/src/libs/fsdrv/lv_fs_win32.c lib/lvgl/src/others/file_explorer/lv_file_explorer.c lib/lvgl/src/others/fragment/lv_fragment.c lib/lvgl/src/others/fragment/lv_fragment_manager.c lib/lvgl/src/others/gridnav/lv_gridnav.c lib/lvgl/src/others/ime/lv_ime_pinyin.c lib/lvgl/src/others/imgfont/lv_imgfont.c lib/lvgl/src/others/monkey/lv_monkey.c lib/lvgl/src/others/observer/lv_observer.c lib/lvgl/src/others/snapshot/lv_snapshot.c lib/lvgl/src/others/sysmon/lv_sysmon.c lib/lvgl/src/layouts/lv_layout.c lib/lvgl/src/layouts/flex/lv_flex.c lib/lvgl/src/layouts/grid/lv_grid.c lib/lvgl/src/tick/lv_tick.c lib/lvgl/src/draw/lv_draw.c lib/lvgl/src/draw/lv_draw_arc.c lib/lvgl/src/draw/lv_draw_buf.c lib/lvgl/src/draw/lv_draw_image.c lib/lvgl/src/draw/lv_draw_label.c lib/lvgl/src/draw/lv_draw_line.c lib/lvgl/src/draw/lv_draw_mask.c lib/lvgl/src/draw/lv_draw_rect.c lib/lvgl/src/draw/lv_draw_triangle.c lib/lvgl/src/draw/lv_image_buf.c lib/lvgl/src/draw/lv_image_decoder.c lib/lvgl/src/draw/sw/lv_draw_sw.c lib/lvgl/src/draw/sw/lv_draw_sw_arc.c lib/lvgl/src/draw/sw/lv_draw_sw_bg_img.c lib/lvgl/src/draw/sw/lv_draw_sw_border.c lib/lvgl/src/draw/sw/lv_draw_sw_box_shadow.c lib/lvgl/src/draw/sw/lv_draw_sw_fill.c lib/lvgl/src/draw/sw/lv_draw_sw_gradient.c lib/lvgl/src/draw/sw/lv_draw_sw_img.c lib/lvgl/src/draw/sw/lv_draw_sw_letter.c lib/lvgl/src/draw/sw/lv_draw_sw_line.c lib/lvgl/src/draw/sw/lv_draw_sw_mask.c lib/lvgl/src/draw/sw/lv_draw_sw_mask_rect.c lib/lvgl/src/draw/sw/lv_draw_sw_transform.c lib/lvgl/src/draw/sw/lv_draw_sw_triangle.c lib/lvgl/src/draw/sw/blend/lv_draw_sw_blend.c lib/lvgl/src/draw/sw/blend/lv_draw_sw_blend_to_argb8888.c lib/lvgl/src/draw/sw/blend/lv_draw_sw_blend_to_rgb565.c lib/lvgl/src/draw/sw/blend/lv_draw_sw_blend_to_rgb888.c lib/lvgl/src/display/lv_display.c lib/lvgl/src/osal/lv_os_none.c lib/lvgl/src/font/lv_font.c lib/lvgl/src/font/lv_font_fmt_txt.c lib/lvgl/src/font/lv_font_montserrat_14.c lib/lvgl/src/themes/lv_theme.c lib/lvgl/src/themes/basic/lv_theme_basic.c lib/lvgl/src/themes/default/lv_theme_default.c lib/lvgl/src/themes/mono/lv_theme_mono.c lib/lvgl/src/widgets/arc/lv_arc.c lib/lvgl/src/widgets/bar/lv_bar.c lib/lvgl/src/widgets/button/lv_button.c lib/lvgl/src/widgets/buttonmatrix/lv_buttonmatrix.c lib/lvgl/src/widgets/calendar/lv_calendar.c lib/lvgl/src/widgets/calendar/lv_calendar_header_arrow.c lib/lvgl/src/widgets/calendar/lv_calendar_header_dropdown.c lib/lvgl/src/widgets/canvas/lv_canvas.c lib/lvgl/src/widgets/chart/lv_chart.c lib/lvgl/src/widgets/checkbox/lv_checkbox.c lib/lvgl/src/widgets/dropdown/lv_dropdown.c lib/lvgl/src/widgets/image/lv_image.c lib/lvgl/src/widgets/imgbtn/lv_imgbtn.c lib/lvgl/src/widgets/keyboard/lv_keyboard.c lib/lvgl/src/widgets/label/lv_label.c lib/lvgl/src/widgets/led/lv_led.c lib/lvgl/src/widgets/line/lv_line.c lib/lvgl/src/widgets/list/lv_list.c lib/lvgl/src/widgets/menu/lv_menu.c lib/lvgl/src/widgets/msgbox/lv_msgbox.c lib/lvgl/src/widgets/objx_templ/lv_objx_templ.c lib/lvgl/src/widgets/roller/lv_roller.c lib/lvgl/src/widgets/scale/lv_scale.c lib/lvgl/src/widgets/slider/lv_slider.c lib/lvgl/src/widgets/span/lv_span.c lib/lvgl/src/widgets/spinbox/lv_spinbox.c lib/lvgl/src/widgets/spinner/lv_spinner.c lib/lvgl/src/widgets/switch/lv_switch.c lib/lvgl/src/widgets/table/lv_table.c lib/lvgl/src/widgets/tabview/lv_tabview.c lib/lvgl/src/widgets/textarea/lv_textarea.c lib/lvgl/src/widgets/tileview/lv_tileview.c lib/lvgl/src/widgets/win/lv_win.c -cflags -Wno-macro-redefined -Wno-extern-initializer -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion -Wno-int-to-pointer-cast -- lib/lvgl_drv/win32drv.c 


REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\microui\microui.c"

SET addCSourceFile=

IF NOT EXIST %CD%\bin\ReleaseStrip (
  MKDIR %CD%\bin\ReleaseStrip 
)
IF NOT EXIST %CD%\bin\ReleaseStrip\obj (
  MKDIR %CD%\bin\ReleaseStrip\obj
)

REM GET CURRENT FOLDER NAME
for %%* in (%CD%) do SET ProjectName=%%~n*

SET rcmd=
IF EXIST "*.rc" (
  SET rcmd=-rcflags /c65001 -- %CD%\%ProjectName%.rc
)

SET libc=
FINDSTR /L linkLibC build.zig > NUL && (
  SET libc=-lc
)

REM OUTPUT TO ZIG_REPORT.EXE
> bin/ReleaseStrip/obj/zig_report.txt (
  zig build-exe -O ReleaseSmall %rcmd% %libc% -fstrip -fsingle-threaded --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -ftime-report -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile% 
) 2>&1 

IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.exe.obj" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.exe.obj %CD%\bin\ReleaseStrip\obj > NUL
)

ECHO.
ECHO Done!
