/**
 * File              : http.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 13.08.2023
 * Last Modified Date: 16.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "cVK.h"
#include <curl/curl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

struct string {
	char *ptr;
	size_t len;
};

static void init_string(struct string *s) {
	s->len = 0;
	s->ptr = malloc(s->len+1);
	if (!s->ptr){
		perror("malloc");
		return;
	}
	s->ptr[0] = '\0';
}

size_t writefunc(void *ptr, size_t size, 
		size_t nmemb, struct string *s)
{
	size_t new_len = s->len + size*nmemb;
	s->ptr = realloc(s->ptr, new_len+1);
	if (!s->ptr){
		perror("malloc");
		return 0;
	}
	memcpy(s->ptr+s->len, ptr, size*nmemb);
	s->ptr[new_len] = '\0';
	s->len = new_len;

	return size*nmemb;
}


int c_vk_run_method(
		const char *token,
		cJSON *content,
		void *user_data, 
		void (*callback)(void *user_data, const cJSON *response, const char *error),
		const char *method, ...)
{
	const char * http_method = "GET";
	char *body = NULL;    // content string
	size_t body_len = 0;  // content length
	
	if (content){
		body = cJSON_Print(content);
		body_len = strlen(body);
		http_method = "POST";
	}

	char authorization[BUFSIZ];
	sprintf(authorization, 
			"Authorization: Bearer %s", token);

	CURL *curl = curl_easy_init();
		
	struct string s;
	init_string(&s);
	
	if(!curl) {
		if (callback)
			callback(user_data, NULL, "Can't init cURL");
		return -1;
	}
		
	char requestString[BUFSIZ];	
	sprintf(requestString, "%s%s", API_URL, method);
	va_list argv;
	va_start(argv, method);
	const char *arg = va_arg(argv, const char*);
	if (arg) {
		sprintf(requestString, "%s?%s", requestString, arg);
		arg = va_arg(argv, const char*);	
	}
	while (arg) {
		sprintf(requestString, "%s&%s", requestString, arg);
		arg = va_arg(argv, const char*);	
	}
	va_end(argv);

	// vk api version
	sprintf(requestString, "%s&v=%s", requestString, VK_API);
	printf("REQUEST: %s\n", requestString);

	curl_easy_setopt(curl, CURLOPT_URL, requestString);
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, http_method);		
	curl_easy_setopt(curl, CURLOPT_HEADER, 0);
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

	/* enable verbose for easier tracing */
	/*curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);		*/

	struct curl_slist *header = NULL;
	header = curl_slist_append(header, 
			"Content-Type: multipart/form-data");
	header = curl_slist_append(header, authorization);
	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);

	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);

	if (body) {
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, body_len);
	}

	CURLcode res = curl_easy_perform(curl);

	if (res) { //handle erros
		if (callback)
			callback(user_data, NULL, curl_easy_strerror(res));
		curl_easy_cleanup(curl);
		curl_slist_free_all(header);
		free(s.ptr);
		return -1;			
	}		
	curl_easy_cleanup(curl);
	curl_slist_free_all(header);
	
	//parse JSON answer
	cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
	if (json){
		cJSON *responce =
			cJSON_GetObjectItem(json, "responce");
		if (responce){
			if (callback)
				callback(user_data, responce, NULL);
			cJSON_free(json);
			free(s.ptr);		
			return 0;
		} else {
		// try to get error
			cJSON *error =
				cJSON_GetObjectItem(json, "error");
			if (error){
				cJSON *msg = 
					cJSON_GetObjectItem(error, "error_msg");
				if (msg){
					if (callback)
						callback(user_data, NULL, msg->valuestring);
				}
			}
		}
		cJSON_free(json);
	} else {
		if (callback){
			char msg[BUFSIZ];
			snprintf(msg, BUFSIZ-1, "Error. Server retuned: %s", s.ptr);
				callback(user_data, NULL, msg);
		}
	}
	
	free(s.ptr);		
	return -1;
}
