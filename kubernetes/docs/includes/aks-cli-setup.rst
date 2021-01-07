Log in via the Azure CLI from your terminal (this should open a window in your browser):

.. sourcecode:: bash

    az login

List your Azure subscription and identify the one you wish to use for this example.

.. sourcecode:: bash

    az account list -o table

Set the active Azure subription via the Azure CLI.

.. sourcecode:: bash

    az account set --subscription {{ azure subscription name }}

List your Azure resource groups and identify the one you wish to use for this example.

.. sourcecode:: bash

    az group list -o table