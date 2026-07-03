import ants
import sys

def denoise_nlm(input_image, output_image):
    # Load the input image
    img = ants.image_read(input_image)

    # Apply NLM denoising
    denoised = ants.denoise_image(img)

    # Save the denoised image
    ants.image_write(denoised, output_image)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} INPUT_NII OUTPUT_NII")
        sys.exit(1)
    img_in = sys.argv[1]
    img_out = sys.argv[2]
    denoise_nlm(img_in, img_out)