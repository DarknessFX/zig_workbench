////////////////////////////////////////////////////////////
//
// SFML - Simple and Fast Multimedia Library
// Copyright (C) 2007-2024 Laurent Gomila (laurent@sfml-dev.org)
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it freely,
// subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented;
//    you must not claim that you wrote the original software.
//    If you use this software in a product, an acknowledgment
//    in the product documentation would be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such,
//    and must not be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source distribution.
//
////////////////////////////////////////////////////////////

#ifndef SFML_RECT_H
#define SFML_RECT_H

////////////////////////////////////////////////////////////
// Headers
////////////////////////////////////////////////////////////
#include <CSFML2/include/Graphics/Export.h>

#include <CSFML2/include/System/Vector2.h>


////////////////////////////////////////////////////////////
/// sfFloatRect and sfIntRect are utility classes for
/// manipulating rectangles.
////////////////////////////////////////////////////////////
typedef struct
{
    float left;
    float top;
    float width;
    float height;
} sfFloatRect;

typedef struct
{
    int left;
    int top;
    int width;
    int height;
} sfIntRect;

////////////////////////////////////////////////////////////
/// \brief Check if a point is inside a rectangle's area
///
/// \param rect Rectangle to test
/// \param x    X coordinate of the point to test
/// \param y    Y coordinate of the point to test
///
/// \return sfTrue if the point is inside
///
////////////////////////////////////////////////////////////
CSFML_GRAPHICS_API sfBool sfFloatRect_contains(const sfFloatRect* rect, float x, float y);
CSFML_GRAPHICS_API sfBool sfIntRect_contains(const sfIntRect* rect, int x, int y);

////////////////////////////////////////////////////////////
/// \brief Check intersection between two rectangles
///
/// \param rect1        First rectangle to test
/// \param rect2        Second rectangle to test
/// \param intersection Rectangle to be filled with overlapping rect (can be NULL)
///
/// \return sfTrue if rectangles overlap
///
////////////////////////////////////////////////////////////
CSFML_GRAPHICS_API sfBool sfFloatRect_intersects(const sfFloatRect* rect1, const sfFloatRect* rect2, sfFloatRect* intersection);
CSFML_GRAPHICS_API sfBool sfIntRect_intersects(const sfIntRect* rect1, const sfIntRect* rect2, sfIntRect* intersection);

////////////////////////////////////////////////////////////
/// \brief Get the position of the rectangle's top-left corner
///
/// \return Position of rectangle
///
/// \see getSize
///
////////////////////////////////////////////////////////////
CSFML_GRAPHICS_API sfVector2f sfFloatRect_getPosition(const sfFloatRect* rect);
CSFML_GRAPHICS_API sfVector2i sfIntRect_getPosition(const sfIntRect* rect);

////////////////////////////////////////////////////////////
/// \brief Get the size of the rectangle
///
/// \return Size of rectangle
///
/// \see getPosition
///
////////////////////////////////////////////////////////////
CSFML_GRAPHICS_API sfVector2f sfFloatRect_getSize(const sfFloatRect* rect);
CSFML_GRAPHICS_API sfVector2i sfIntRect_getSize(const sfIntRect* rect);


#endif // SFML_RECT_H
