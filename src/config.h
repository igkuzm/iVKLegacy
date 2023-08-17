/**
 * File              : config.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 13.08.2023
 * Last Modified Date: 13.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#ifndef CONFIG_H
#define CONFIG_H

// Vkontakte API version
#define  VK_API       "5.131"

// Use verify SSL in curl. On old systems old not
// working SSL certificates - curl may falt
#define  VERIFY_SSL   0

// Default port to listen to catch token during 
// authorisation
#define  DEFAULT_PORT 2000

// VK API url
#define API_URL       "https://api.vk.com/method/"

#endif /* ifndef CONFIG_H */
