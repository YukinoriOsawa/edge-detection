import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["originalImage", "processedImage", "thresholdValue", "submitButton", "loading"]

  connect() {
    console.log("Image processor controller connected")
    window.addEventListener('resize', () => {
      if (this.originalImageTarget.src) {
        this.resizeImage(this.originalImageTarget)
      }
      if (this.processedImageTarget.src) {
        this.resizeImage(this.processedImageTarget)
      }
    })
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.originalImageTarget.src = e.target.result
        this.originalImageTarget.onload = () => this.resizeImage(this.originalImageTarget)
      }
      reader.readAsDataURL(file)
    }
  }

  updateThreshold(event) {
    this.thresholdValueTarget.textContent = event.target.value
  }

  processImage(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    this.loadingTarget.classList.remove('hidden')
    this.submitButtonTarget.disabled = true

    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        this.processedImageTarget.src = data.processed_image
        this.processedImageTarget.onload = () => this.resizeImage(this.processedImageTarget)
      } else {
        alert(data.message || 'エラーが発生しました')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('エラーが発生しました')
    })
    .finally(() => {
      this.loadingTarget.classList.add('hidden')
      this.submitButtonTarget.disabled = false
    })
  }

  resizeImage(img) {
    const maxWidth = img.parentElement.clientWidth
    const maxHeight = img.parentElement.clientHeight
    const ratio = Math.min(maxWidth / img.naturalWidth, maxHeight / img.naturalHeight)

    if (ratio < 1) {
      img.style.width = `${img.naturalWidth * ratio}px`
      img.style.height = `${img.naturalHeight * ratio}px`
    } else {
      img.style.width = ''
      img.style.height = ''
    }
  }
}

