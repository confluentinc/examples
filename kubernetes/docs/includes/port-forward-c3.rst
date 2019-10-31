In order to view |c3|, network connectivity will need to be available between your local machine and the Kubernetes pod running the |c3| service.  If you used an existing cluster you may already have external cluster access configured.  If you used the demo ``gke-create-cluster`` function, you can use the following ``kubectl`` command to open a forwarded port connection between your local host and |c3|.

.. sourcecode:: bash

		kubectl -n operator port-forward controlcenter-0 12345:9021
