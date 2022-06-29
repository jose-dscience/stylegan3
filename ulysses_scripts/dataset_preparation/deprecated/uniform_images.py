import os, sys
file_path = 'additionalmodules/'
DIR = os.path.dirname(__file__)
sys.path.append(os.path.dirname(file_path))
sys.path.append(os.path.join(DIR, './additionalmodules/PIL.egg'))

from absl import app
from absl import flags
from absl import logging
from hashlib import md5
from math import ceil
from os import makedirs
from os.path import isdir
from PIL import Image
from re import compile as re_compile
import glob

FLAGS = flags.FLAGS
flags.DEFINE_integer('size', 128, 'The size of the square images to crop.')
flags.DEFINE_integer('stride', 32, 'The stride of the sliding crop window.')
flags.DEFINE_integer('min_colors', 5, 'The minimum number of colors per crop.')
flags.DEFINE_string('input_data', './blasphemous_data',
                    'The file containing the source image folder.')
flags.DEFINE_string('images_dir', 'blasphemous_data_uniformed',
                    'The image directory in which to save the crops.')
flags.DEFINE_string('image_format', 'png',
                    'The format under which to save images.')
flags.DEFINE_string('continue_from', '', 'Resume from the provided image name')

SCALE_PATTERN = re_compile('r^.*-(\d+)x.png$')


def main(_):
    ''' #COMMENTED FOR PROBLEMS WITH PERMISSIONS
    if not isdir(FLAGS.images_dir):
        makedirs(FLAGS.images_dir)
    '''
    
    print("Reading files in " + FLAGS.input_data)
    file_list = glob.glob(FLAGS.input_data+"/*")
    idx=0
    num_of_images=len(file_list)
    if FLAGS.continue_from != '':
        try:
            image_path = FLAGS.input_data + "/" + FLAGS.continue_from
            idx=file_list.index(image_path)
            file_list = file_list[idx:len(file_list)]
            print("Continuing from index " + str(idx) + ".")
        except:
            raise IndexError("Element \"" + image_path + "\" not found in the list of files.")
    else:
        print('Starting from the beginning.')
                                    
    for filename in file_list:
        idx+=1
        logging.info('[%d/%d %f percent] Processing %s.' % (idx, num_of_images, idx*100.0/num_of_images, filename))
        image = Image.open(filename).convert('RGBA')
        image = image.convert('RGB')
        image_hash = md5(filename.encode()).hexdigest()

        # Resize to pixel size of 1, if needed.
        scale_match = SCALE_PATTERN.match(filename)
        #logging.info(scale_match)############################
        #if scale_match:
        #    scale = int(scale_match.group(1))
        #    logging.warning('Resizing by %dx' % scale)
        #    image = image.resize((image.width // scale,
        #                              image.height // scale), Image.NEAREST)
        
        #scale = 300./image.width
        #image = image.resize((int(image.width*scale), int(image.height*scale)), Image.NEAREST)
        
        # Divide the image into squares. If it doesn't evenly divide, shift
        # the last crops in to avoid empty areas.
        for y in range(ceil(image.height / FLAGS.stride)):
            y_min = y * FLAGS.stride
            y_max = y * FLAGS.stride + FLAGS.size

            if y_max > image.height:
                y_max = image.height
                y_min = y_max - FLAGS.size

            for x in range(ceil(image.width / FLAGS.stride)):
                x_min = x * FLAGS.stride
                x_max = x * FLAGS.stride + FLAGS.size

                if x_max > image.width:
                    x_max = image.width
                    x_min = x_max - FLAGS.size

                # Create the cropped image.
                crop = image.crop((x_min, y_min, x_max, y_max))

                # Discard predominantly empty crops.
                colors = crop.getcolors()
                if colors and len(colors) < FLAGS.min_colors:
                    logging.warning('Skipping empty crop')
                    continue

                # Save the image
                name = '%s/%s_%d_%d.%s' % (FLAGS.images_dir, image_hash, y,
                                               x, FLAGS.image_format)
                crop.save(name, FLAGS.image_format)
                logging.info('Saved %s' % name)


if __name__ == '__main__':
    app.run(main)
