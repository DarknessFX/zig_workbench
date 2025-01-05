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

#ifndef SFML_CONTEXT_H
#define SFML_CONTEXT_H

////////////////////////////////////////////////////////////
// Headers
////////////////////////////////////////////////////////////
#include <CSFML2/include/Window/Export.h>
#include <CSFML2/include/Window/Types.h>
#include <CSFML2/include/Window/Window.h>

typedef void (*GlFunctionPointer)(void);

////////////////////////////////////////////////////////////
/// \brief Create a new context
///
/// This function activates the new context.
///
/// \return New sfContext object
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API sfContext* sfContext_create(void);

////////////////////////////////////////////////////////////
/// \brief Destroy a context
///
/// \param context Context to destroy
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API void sfContext_destroy(sfContext* context);

////////////////////////////////////////////////////////////
/// \brief Check whether a given OpenGL extension is available.
///
/// \param name Name of the extension to check for
///
/// \return True if available, false if unavailable
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API sfBool sfContext_isExtensionAvailable(const char* name);

////////////////////////////////////////////////////////////
/// \brief Activate or deactivate explicitely a context
///
/// \param context Context object
/// \param active  sfTrue to activate, sfFalse to deactivate
///
/// \return sfTrue on success, sfFalse on failure
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API sfBool sfContext_setActive(sfContext* context, sfBool active);

////////////////////////////////////////////////////////////
/// \brief Get the address of an OpenGL function.
///
/// \param name Name of the function to get the address of
///
/// \return Address of the OpenGL function, 0 on failure
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API GlFunctionPointer sfContext_getFunction(const char* name);

////////////////////////////////////////////////////////////
/// \brief Get the settings of the context.
///
/// \param context Context object
///
/// Note that these settings may be different than the ones passed to the
/// constructor; they are indeed adjusted if the original settings are not
/// directly supported by the system.
///
/// \return Structure containing the settings
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API sfContextSettings sfContext_getSettings(const sfContext* context);

////////////////////////////////////////////////////////////
/// \brief Get the currently active context's ID
///
/// The context ID is used to identify contexts when
/// managing unshareable OpenGL resources.
///
/// \return The active context's ID or 0 if no context is currently active
///
////////////////////////////////////////////////////////////
CSFML_WINDOW_API sfUint64 sfContext_getActiveContextId(void);

#endif // SFML_CONTEXT_H
