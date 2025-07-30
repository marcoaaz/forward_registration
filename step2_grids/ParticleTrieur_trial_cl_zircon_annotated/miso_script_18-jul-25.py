
# -*- coding: utf-8 -*-
"""


Created on Tue Oct 8, 11:20 AM, Marco Acevedo
Updated: 18-Jul-25, M.A.

Notes:
Working environment: .conda (Python 3.9.20)
The requirements are listed in 'requirements.txt' ('requirements_base.txt' was for my whole operative system)

To activate conda environment (Command Prompt only):
check that it exist:        conda info --envs
activate:     conda activate "e:\Feb-March_2024_zircon imaging\ParticleTrieur_trial_cl_zircon_annotated\.conda"

"""


import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

from miso.training.parameters import MisoParameters
from miso.training.trainer import train_image_classification_model

tp = MisoParameters()

# -----------------------------------------------------------------------------
# Name 
# -----------------------------------------------------------------------------
# Name of this training run (leave as "" to auto-generate
tp.name = r"test3"

# Description of this training run (leave as "" to auto-generate
tp.description = None
# -----------------------------------------------------------------------------
# Dataset
# -----------------------------------------------------------------------------
# Source directory (local folder or download link to dataset)
#tp.dataset.source = r"E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\classified_14-sep-24\kate_john.xml"
tp.dataset.source = r"E:\Feb-March_2024_zircon imaging\02_John Caulfield_files\classified_14-sep-24\John-Kate_04_10_2024\project_exported.xml"

# Minimum number of images to include in a class
tp.dataset.min_count = 200 #150

# Whether to map the images in class with not enough examples to an "others" class
tp.dataset.map_others = False
# Fraction of dataset used for validation
tp.dataset.val_split = 0.2
# Random seed used to split the dataset into train and validation
tp.dataset.random_seed = 0

#Keep changing this directory
# Set to a local directory to stored the loaded dataset on disk instead of in memory
tp.dataset.memmap_directory = r"C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Miso_temp"

# -----------------------------------------------------------------------------
# CNN
# -----------------------------------------------------------------------------
# CNN type
# Transfer learning:
# - resnet50_tl
# - resnet50_cyclic_tl
# - resnet50_cyclic_gain_tl
# Full network (custom)
# - base_cyclic
# - resnet_cyclic
# Full network (keras applications / qubvel image_classifiers)
# - resnet[18,34,50]
# - vgg[16,19]
# - efficientnetB[0-7]
tp.cnn.id = r"resnet50_cyclic_tl" 
#"resnet50_cyclic_tl" 23 min with 224x224x3, 76 min with 448x448x3
#"resnet50v2" 15 hr 12 min

# Input image shape, set to None to use default size ([128, 128, 1] for custom, [224, 224, 3] for others)
tp.cnn.img_shape = [224, 224, 3] #[384, 384, 3] Input 0 of layer "model" is incompatible with the layer: expected shape=(None, 416, 416, 3), found shape=(None, 224, 224, 3)
print(tp.cnn.img_shape)
# Input image colour space [greyscale/rgb]
tp.cnn.img_type = "rgb"
# Number of filters in first block (custom networks)
tp.cnn.filters = 16
# Number of blocks (custom networks), set to None for automatic selection
tp.cnn.blocks = None
# Size of dense layers (custom networks / transfer learning) as a list, e.g. [512, 512] for two dense layers size 512
tp.cnn.dense = None
# Whether to use batch normalisation
tp.cnn.use_batch_norm = True
# Type of pooling [avg, max, none]
tp.cnn.global_pooling = "avg" #avg
# Type of activation
tp.cnn.activation = "relu"
# Use A-Softmax
tp.cnn.use_asoftmax = False

# -----------------------------------------------------------------------------
# Training
# -----------------------------------------------------------------------------
# Number of images for each training step (default= 32; recommended 64)
tp.training.batch_size = 64
# Number of epochs after which training is stopped regardless
tp.training.max_epochs = 10000

#alr_epochs= 40 for 200 images/class; 5-10 for >1K images/class
# Number of epochs to monitor for no improvement by the adaptive learning rate scheduler.
# After no improvement for this many epochs, the learning rate is dropped by half
tp.training.alr_epochs = 40 #10
# Number of learning rate drops after which training is suspended
tp.training.alr_drops = 4
# Monitor the validation loss instead?
tp.training.monitor_val_loss = False
# Use class weighting? #tell the model how much it should weigh every class samples in training procedure
tp.training.use_class_weights = True
# Use class balancing via random over sampling? (Overrides class weights)
tp.training.use_class_undersampling = False #'RandomUnderSampler' object has no attribute 'fit_sample'
# Use train time augmentation?
tp.training.use_augmentation = True

# -----------------------------------------------------------------------------
# Augmentation
# -----------------------------------------------------------------------------
# Setting depends on the size of list passed:
# - length 2, e.g. [low, high] = random value between low and high
# - length 3 or more, e.g. [a, b, c] = choose a random value from this list
# Rotation
tp.augmentation.rotation = [0, 360]
# Gain: I' = I * gain #[0.8, 1.0, 1.2]
tp.augmentation.gain = [0.8, 1.0, 1.2]
# Gamma: I' = I ^ gamma #[0.5, 1.0, 2.0]
tp.augmentation.gamma = [0.5, 1.0, 2.0]
# Bias: I' = I + bias
tp.augmentation.bias = None
# Zoom: I'[x,y] = I[x/zoom, y/zoom] #[0.9, 1.0, 1.1]
tp.augmentation.zoom = None
# Gaussian noise std deviation
tp.augmentation.gaussian_noise = [0.01, 0.1]
# The parameters for the following are not random
# Random crop, e.g. [224, 224, 3]
# If random crop is used, you MUST set the original image size that the crop is taken from
tp.augmentation.random_crop = None
tp.augmentation.orig_img_shape = [448, 448, 3]

# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------
# Directory to save output
tp.output.save_dir = r"E:\Feb-March_2024_zircon imaging\ParticleTrieur_trial_cl_zircon_annotated\trained model_18-Jul-25"
# Save model?
tp.output.save_model = True
# Save the mislabelled image analysis?
tp.output.save_mislabeled = False

# Train the model!!!
import time
import tempfile
from datetime import datetime
import numpy as np
from miso.utils import singleton
# Guard for windows
if __name__ == "__main__":
    # Only one script at a time
    start = time.time()
    done = False
    while not done:
        try:
            fn = os.path.join(tempfile.gettempdir(), "miso.lock")
            with open(fn, 'w+') as fh:
                fh.write('miso')
            try:
                os.chmod(fn, 0o777)
            except OSError:
                pass
            lock = singleton.SingleInstance(lockfile=fn)
            print()
            #train_image_classification_model(tp)
            keras_model, vector_model, datasource, result = train_image_classification_model(tp)                                   
            
            #vector_model: Sub-model of the trained model that outputs the feature vector.
            #datasource: The training and test images and class labels.
            #result: The results of training: accuracy and per-class precision and recall.
            
            #destFolder = tp.output.save_dir
            #os.path.join(destFolder, 'v.csv')
            #numpy.savetxt("foo.csv", a, delimiter=",")

            done = True

        except singleton.SingleInstanceException:
            print("{}: Another script is already running, trying again in 10 seconds. ({}s waiting)\r".format(datetime.now(), np.round(time.time() - start)), end='')
            time.sleep(10)