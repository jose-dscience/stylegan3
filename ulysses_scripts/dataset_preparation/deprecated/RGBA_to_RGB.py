from absl import app
from absl import flags
from absl import logging
from hashlib import md5
from os import makedirs
from os.path import isdir
from PIL import Image
from re import compile as re_compile
import glob

FLAGS = flags.FLAGS
flags.DEFINE_string('input_dir', './input',
                    'The directory containing the RGBA images.')
flags.DEFINE_string('output_dir', './output',
                    'The image directory in which to save the RGB images.')
flags.DEFINE_string('image_format', 'png',
                    'The format under which to save images.')
flags.DEFINE_string('start_from', '1',
                    'Skip up to start_from-1 files.')

SCALE_PATTERN = re_compile('r^.*-(\d+)x.png$')

def main(_):
    if not isdir(FLAGS.output_dir):
        makedirs(FLAGS.output_dir)

    number_of_images = len(glob.glob(FLAGS.input_dir+"/*"))
    
    images=glob.glob(FLAGS.input_dir+"/*")
    
    logging.info('It will be processed %d images skipping the first %d ones.' %  (number_of_images, int(FLAGS.start_from)-1))

    first=int(FLAGS.start_from)-1
    for i in range(first, number_of_images):
        filename=images[i]
        logging.info('   -[%d/%d] Processing %s' % (i+1, number_of_images, filename))
        image = Image.open(filename).convert('RGBA')
        new_image = image.convert('RGB')
        image_hash = md5(filename.encode()).hexdigest()

        # Save the image
        name = '%s/%s.%s' % (FLAGS.output_dir, image_hash, FLAGS.image_format)
        new_image.save(name, FLAGS.image_format)
        i+=1


if __name__ == '__main__':
    app.run(main)
