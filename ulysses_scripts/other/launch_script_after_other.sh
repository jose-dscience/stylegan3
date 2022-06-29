RUNNING_SCRIPT=RGBA_to_RGB.py
NEW_SCRIPT_PATH="python3 ../dataset_tool.py create_from_images ../dataset/blasphemous ../blasphemous_data_uniformed_RGB/"

pid=$(ps -opid= -C $RUNNING_SCRIPT)
while [ -d /proc/$pid ] ; do
    sleep 1
done && $NEW_SCRIPT_PATH
