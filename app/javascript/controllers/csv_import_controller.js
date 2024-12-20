import { Controller } from "@hotwired/stimulus";
import Swal from "sweetalert2";

export default class extends Controller {
  static targets = ["fileInput", "importButton", "deleteButton"]

  connect() {
    this.importButtonTarget.disabled = true;
  }

  enableButton() {
    this.importButtonTarget.disabled = !this.fileInputTarget.files.length;
  }

  async import(event) {
    event.preventDefault();
    const file = this.fileInputTarget.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append("file", file);

    Swal.fire({
      title: "Importing CSV",
      html: '<b>Progress:</b> <span id="percent">0</span>%',
      allowOutsideClick: false,
      didOpen: () => {
        Swal.showLoading();
      }
    });

    let percent = 0;

    // Tăng phần trăm theo thời gian
    const progressInterval = setInterval(() => {
      if (percent < 95) {
        percent += Math.floor(Math.random() * 5) + 1;
        document.getElementById("percent").innerText = Math.min(percent, 95);
      }
    }, 300);

    try {
      const response = await fetch("/materials/import_csv", {
        method: "POST",
        body: formData,
        headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
      });

      const result = await response.json();
      clearInterval(progressInterval);

      if (response.ok) {
        document.getElementById("percent").innerText = 100;
        Swal.fire({
          icon: "success",
          title: "Import Successful!",
          text: result.message
        });

        // Đợi một chút trước khi reload trang
        setTimeout(() => {
          window.location.reload();
        }, 2000);
      } else {
        Swal.fire({
          icon: "error",
          title: "Import Failed!",
          text: result.errors.join(", ")
        });
      }
    } catch (error) {
      clearInterval(progressInterval);
      Swal.fire({
        icon: "error",
        title: "Error!",
        text: "Something went wrong!"
      });
    }
  }

  async deleteAllImportedMaterials(event) {
    event.preventDefault();

    const confirmation = confirm("Are you sure you want to delete all imported materials?");
    if (!confirmation) {
      return;
    }

    try {
      const response = await fetch("/materials/delete_all_imported", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
      });

      const result = await response.json();

      if (result.success) {
        Swal.fire({
          icon: "success",
          title: "Successfully",
          text: 'Deleted successfully'
        }).then((result) => {
          if (result.isConfirmed) {
            location.reload();
          }
        });
      } else {
        Swal.fire({
          icon: "error",
          title: "Error!",
          text: result.message
        });
      }
    } catch (error) {
      Swal.fire({
        icon: "error",
        title: "Error!",
        text: error.message,
      });
    }
  }
}
