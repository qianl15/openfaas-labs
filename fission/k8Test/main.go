/*
  Test: Created by Franky
*/

// Note: the example only works with the code within the same release/branch.
package main

import (
	//"bufio"
	"flag"
	"fmt"
	//"os"
  //"reflect" // Used for TypeOf
	"path/filepath"

	//appsv1 "k8s.io/api/apps/v1"
	//apiv1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
	//"k8s.io/client-go/util/retry"
)

func main() {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		panic(err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}

  namesp := "fission-function"

	deploymentsClient := clientset.AppsV1().Deployments(namesp)
  podClient := clientset.CoreV1().Pods(namesp)

	// List Deployments
	fmt.Printf("Listing deployments in namespace %q:\n", namesp)
	list, err := deploymentsClient.List(metav1.ListOptions{})
	if err != nil {
		panic(err)
	}
	for _, d := range list.Items {
		fmt.Printf(" * %s (%d replicas)\n", d.Name, *d.Spec.Replicas)
	}

	// Pods Deployments
	fmt.Printf("Listing pods in namespace %q:\n", namesp)
	listPods, err := podClient.List(metav1.ListOptions{})
	if err != nil {
		panic(err)
	}
	for _, d := range listPods.Items {
		fmt.Printf(" * %s; Node Name: %s\n", d.Name, d.Spec.NodeName)
    for _, p := range d.Spec.Containers {
      fmt.Printf(" * * Container name: %s\n", p.Name)
    }
	}

}

func int32Ptr(i int32) *int32 { return &i }
