const socket = new WebSocket('ws://localhost:4040/test/websocket');

socket.addEventListener('message', (event) => {
    const data = JSON.parse(event.data);

    switch(data.type) {
        case 'white':
            console.log(data.detail);
            break;
        case 'black':
            console.log(data.detail);
            break;
        default:
            console.error('Unknown message type:', data.type);
    }
});