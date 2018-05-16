
#ifndef CDOC_EXPORT_H
#define CDOC_EXPORT_H

#ifdef CDOC_STATIC_DEFINE
#  define CDOC_EXPORT
#  define CDOC_NO_EXPORT
#else
#  ifndef CDOC_EXPORT
#    ifdef cdoc_EXPORTS
        /* We are building this library */
#      define CDOC_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define CDOC_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef CDOC_NO_EXPORT
#    define CDOC_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef CDOC_DEPRECATED
#  define CDOC_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef CDOC_DEPRECATED_EXPORT
#  define CDOC_DEPRECATED_EXPORT CDOC_EXPORT CDOC_DEPRECATED
#endif

#ifndef CDOC_DEPRECATED_NO_EXPORT
#  define CDOC_DEPRECATED_NO_EXPORT CDOC_NO_EXPORT CDOC_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef CDOC_NO_DEPRECATED
#    define CDOC_NO_DEPRECATED
#  endif
#endif

#endif
