# Communications (Notificaciones)
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: NotificationsModule — 7 endpoints. Notificaciones: send (a usuario), broadcast (a todos), club notification (a instancia de club). FCM tokens: register, unregister, get own tokens, get by userId. Controllers: NotificationsController, FcmTokensController. Integra FirebaseAdminModule (FCM).
- **Admin**: 1 page funcional (notifications). Formularios de envio: notificacion directa a usuario, broadcast a todos, notificacion a club por tipo/instancia. Consume POST /notifications/send, POST /notifications/broadcast, POST /notifications/club/:type/:id.
- **App**: No tiene screens de notificaciones. Consume FCM tokens para push notifications (registro/desregistro via providers). Firebase Messaging integrado para recepcion.
- **DB**: user_fcm_tokens

## Que define el canon
- Canon runtime 6.6 menciona notificaciones como capacidad operativa
- Canon runtime 9 documenta Firebase Admin (FCM) como integracion configurada

## Gap
- Admin no tiene listado de notificaciones enviadas — solo formularios de envio
- App no tiene UI para historial de notificaciones, solo recibe push

## Prioridad
- A definir por el desarrollador
