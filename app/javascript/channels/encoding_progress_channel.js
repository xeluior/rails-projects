import consumer from "channels/consumer"

const subscriptions = []
document.addEventListener('turbo:load', () => {
  const attachements = Array.from(document.querySelectorAll('[data-blob-id]'))
  const blobs = attachements.map((attachement) => attachement.dataset.blobId)
  for (const blob of blobs) {
    if (subscriptions[blob]) return
    
    subscriptions[blob] = consumer.subscriptions.create({
      channel: "EncodingProgressChannel",
      blob_id: blob
    }, {
      connected() {
        // Called when the subscription is ready for use on the server
        const attachment = document.querySelector(`[data-blob-id="${blob}"]`)
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
  subscriptions.forEach((sub, i) => {
    if (blobs.includes(`${i}`)) return

    sub.unsubscribe()
    delete subscriptions[i]
  })
})
