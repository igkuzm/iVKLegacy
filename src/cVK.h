/**
 * File              : cVK.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 11.08.2023
 * Last Modified Date: 16.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#ifndef C_VK_H
#define C_VK_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "cJSON.h"
	

#define  VK_API       "5.131"
#define  VERIFY_SSL   0
#define  DEFAULT_PORT 2000
/*
 * To create new application visit https://vk.com/apps
 * Set Open API ON, basic domen to localhost
 * and addres like 'http://localhost:2000'
 * You will get client_id and client_secret
 */

/*
 * To get access_token: 
 *		1. Get verification code url with c_vk_auth_url. 
 *		2. Start c_vk_get_token to listen DEFAULT_PORT
 *		3. User application should open url in browser, authorise
 *			 and c_vk_get_token will catch the token
 */

// https://dev.vk.com/references/access-rights
// ACCESS-RIGHTS FOR USER
#define AR_NOTIFY       1<<0
#define AR_FRIENDS      1<<1
#define AR_PHOTOS       1<<2
#define AR_AUDIO        1<<3
#define AR_VIDEO        1<<4
#define AR_STORIES      1<<6
#define AR_PAGES        1<<7
#define AR_MENU         1<<8
#define AR_STATUS       1<<10
#define AR_NOTES        1<<11
#define AR_MESSAGES     1<<12
#define AR_WALL         1<<13
#define AR_ADS          1<<15
#define AR_OFFLINE      1<<16 //token has unlimit life, expires_in=0
#define AR_DOCS         1<<17
#define AR_GROUPS       1<<18
#define AR_NOTIFICATION 1<<19
#define AR_STATS        1<<20
#define AR_EMAIL        1<<22
#define AR_MARKET       1<<27
#define AR_PHONE_NUMBER 1<<287

// ACCESS-RIGHTS FOR GROUP
#define ARG_STORIES     1<<0
#define ARG_PHOTOS      1<<2
#define ARG_APP_WIDGET  1<<6
#define ARG_MESSAGES    1<<12
#define ARG_DOCS        1<<17
#define ARG_MANAGE      1<<18

/* return allocated c null-terminated string with 
 * authorisation URL or NULL on error*/
char * c_vk_auth_url(
		const char *client_id,
		uint32_t access_rights //https://dev.vk.com/references/access-rights
		);

/* launch listner on DEFAULT_PORT to catch authorization code
 * and change it to token. */
void c_vk_get_token(
		const char *client_id,         // get in https://vk.com/apps
		const char *client_secret,     // get in https://vk.com/apps
		void * user_data,
		void (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,              // seconds of token life - 0 for immortal
			const char * user_id,
			const char * error)
		);

/* run vk api method and callback json/error
 * Return 0 on success or -1 on error*/
int c_vk_run_method(
		const char *token,  // authorization token
		cJSON *content,     // content of message
		void *user_data, 
		void (*callback)    // response and error handler - NULL-able
				(void *user_data,
				 const cJSON *response,
				 const char *error), 
		const char *method, // method name from vk api
		... );               // - params list - NULL-terminate


#ifdef __cplusplus
}  /* end of the 'extern "C"' block */
#endif

#endif /* ifndef C_VK_H */
