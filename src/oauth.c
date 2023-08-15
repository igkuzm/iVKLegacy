/**
 * File              : oauth.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 11.08.2023
 * Last Modified Date: 13.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <curl/curl.h>
#include <unistd.h>

#include "cJSON.h"
#include "cVK.h"

#define OAUTH_URL "https://oauth.vk.com/authorize"
#define TOKEN_URL "https://oauth.vk.com/access_token"

char * c_vk_auth_url(
		const char *client_id,  
		uint32_t access_rights) //https://dev.vk.com/references/access-rights
{
	char *s = malloc(BUFSIZ);
	if (!s){
		perror("malloc");
		return NULL;
	}
	sprintf(s, 
			"%s?client_id=%s&display=mobile&"
			"redirect_uri=http://localhost:%d&scope=%d&v=%s", 
			OAUTH_URL, client_id, DEFAULT_PORT, access_rights, VK_API);	
	
	return s;
}

static char * c_vk_listner(
		void * user_data,
		void (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * user_id,
			const char * error)
		)
{
    int socket_desc, client_sock, client_size;
    struct sockaddr_in server_addr, client_addr;
    char server_message[2000], client_message[2000];

    // Clean buffers:
    memset(server_message, '\0', sizeof(server_message));
    memset(client_message, '\0', sizeof(client_message));
    
		// Clean sockaddr_in
		memset(&server_addr, '\0', sizeof(server_addr));
		memset(&client_addr, '\0', sizeof(client_addr));

    // Create socket:
    socket_desc = socket(AF_INET, SOCK_STREAM, 0);

    if(socket_desc < 0){
				callback(user_data, NULL, 0, NULL,
						"Error while creating socket");
        return NULL;
    }
    //printf("Socket created successfully\n");

    // Set port and IP:
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(DEFAULT_PORT);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Bind to the set port and IP:
    if(bind(socket_desc, (struct sockaddr*)&server_addr, 
					sizeof(server_addr))<0){
				callback(user_data, NULL, 0, NULL,
						"Couldn't bind to the port");
        return NULL;
    }
    //printf("Done with binding\n");

    // Listen for clients:
    if(listen(socket_desc, 1) < 0){
				callback(user_data, NULL, 0, NULL,
						"Error while listening");
        return NULL;
    }
    //printf("\nListening for incoming connections.....\n");

    // Accept an incoming connection:
    client_size = sizeof(client_addr);
    client_sock = accept(socket_desc, 
				(struct sockaddr*)&client_addr, &client_size);

    if (client_sock < 0){
				callback(user_data, NULL, 0, NULL,
						"Can't accept socket data");
				close(socket_desc);
        return NULL;
    }
    //printf("Client connected at IP: %s and port: %i\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));

    // Receive client's message:
    if (recv(client_sock, client_message, sizeof(client_message), 0) < 0){
				callback(user_data, NULL, 0, NULL,
						"Couldn't receive incoming message");
				close(client_sock);
				close(socket_desc);
        return NULL;
    }
    //printf("Msg from client: %s\n", client_message);
		char *html = strndup(client_message, sizeof(client_message) - 1);
		client_message[sizeof(client_message)-1] = 0;

		// Respond to client:
    strcpy(server_message, "Done!");
		send(client_sock, server_message, strlen(server_message), 0);

    // Closing the socket:
    close(client_sock);
    close(socket_desc);

    return html;
}

static long 
strfnd( 
		const char * haystack, 
		const char * needle
		)
{
	//find position of search word in haystack
	const char *p = strstr(haystack, needle);
	if (p)
		return p - haystack;
	return -1;
}

static char * c_vk_listen_for_code(
		void * user_data,
		void (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * user_id,
			const char * error
			)
		)
{
		char *html = c_vk_listner(user_data, callback);
		if (!html)
			return NULL;

		//find start of verification code
		const char * pattern = "code="; 
		int len = strlen(pattern);
		int start = strfnd(html, pattern); 
		if (start < 0){
			callback(user_data, NULL, 0, NULL,
					"Couldn't find verification code in message");
			return NULL;
		}
		//find end of code
		long end = strfnd(&html[start], " ");

		//find length of verification code
		long clen = end - len;

		//allocate code and copy
		char * code = malloc(clen + 1);
		if (!code){
			callback(user_data, NULL, 0, NULL,
					"error memory allocation");
			return NULL;
		}
		strncpy(code, &html[start + len], clen);
		code[clen] = 0;

		return code;
}

struct string {
	char *ptr;
	size_t len;
};

static void init_string(struct string *s) {
	s->len = 0;
	s->ptr = malloc(s->len+1);
	s->ptr[0] = '\0';
}

static size_t writefunc(void *ptr, size_t size, size_t nmemb, struct string *s)
{
	size_t new_len = s->len + size*nmemb;
	s->ptr = realloc(s->ptr, new_len+1);
	memcpy(s->ptr+s->len, ptr, size*nmemb);
	s->ptr[new_len] = '\0';
	s->len = new_len;

	return size*nmemb;
}

// callback acces token
void c_vk_auth_token(
		const char *client_id, 
		const char *client_secret, 
		void * user_data,
		void (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * user_id,
			const char * error
			)
		)
{
	if (!callback){
		perror("callback is NULL");
		return;
	}

	if (!client_id) {
		callback(user_data, NULL, 0, NULL, "No client_id");
		return;
	}

	if (!client_secret) {
		callback(user_data, NULL, 0, NULL, "No client_secret");
		return;
	}

	// listen for code
	char *code = c_vk_listen_for_code(user_data, callback);
	if (!code)
		return;

	// ask token
	CURL *curl = curl_easy_init();
	if (!curl){
		callback(user_data, NULL, 0, NULL, "Can't init cURL");
		return;
	}

	struct string s;
	init_string(&s);
	
	char str[BUFSIZ];
	sprintf(str, 
		"%s?client_id=%s&client_secret=%s&"
		"redirect_uri=http://localhost:%d&code=%s", 
		TOKEN_URL, client_id, client_secret, DEFAULT_PORT, code);	
	
	curl_easy_setopt(curl, CURLOPT_URL, str);
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "GET");		
	curl_easy_setopt(curl, CURLOPT_HEADER, 0);

	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);
	
	struct curl_slist *header = NULL;
	header = curl_slist_append(header, "Connection: close");		
	header = curl_slist_append(header, 
			"Content-Type: application/x-www-form-urlencoded");		
	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);
	
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

	CURLcode res = curl_easy_perform(curl);

	if (res) { //handle erros
		callback(user_data, NULL, 0, NULL, curl_easy_strerror(res));
		curl_easy_cleanup(curl);
		curl_slist_free_all(header);
		return;			
	}		
	curl_easy_cleanup(curl);
	curl_slist_free_all(header);

	cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
	if (!json){
		char str[BUFSIZ];
		sprintf(str, "Can't parse json. cURL retune: %s", s.ptr);
		callback(user_data, NULL, 0, NULL, str);
		free(s.ptr);
		return;			
	}
	free(s.ptr);
	if (cJSON_IsObject(json)) {
		cJSON *access_token = 
				cJSON_GetObjectItem(json, "access_token");			
		if (!access_token) { //handle errors
			cJSON *error_description = 
					cJSON_GetObjectItem(json, "error_description");
			if (!error_description) {
				//no error code in JSON answer
				callback(user_data, NULL, 0, NULL, "unknown error!"); 
				cJSON_free(json);
				return;
			}
			callback(user_data, NULL, 0, NULL, error_description->valuestring);
			cJSON_free(json);
			return;
		}
		//OK - we have a token
		callback(
				user_data, 
				access_token->valuestring, 
				cJSON_GetObjectItem(json, "expires_in") ?		
						cJSON_GetObjectItem(json, "expires_in")->valueint : 0, 
				cJSON_GetObjectItem(json, "user_id") ? 
						cJSON_GetObjectItem(json, "user_id")->valuestring : NULL, 
				NULL);
		cJSON_free(json);
	}	
}
