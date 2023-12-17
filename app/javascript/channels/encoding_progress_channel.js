import consumer from "channels/consumer"

const attachements = document.querySelectorAll('[data-blob-id]')
for (const attachment of attachements) {
  const blob = attachment.dataset.blobId
  consumer.subscriptions.create({
    channel: "EncodingProgressChannel",
    blob_id: blob
  }, {
    connected() {
      // Called when the subscription is ready for use on the server
      const display = document.createElement('div')
      display.setAttribute('id', `blob-${blob}`)
      display.textContent = "0"
      attachment.appendChild(display)
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(data) {
      // Called when there's incoming data on the websocket for this channel
      const display = document.getElementById(`blob-${blob}`)
      display.textContent = data
    }
  })
}
