using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class SelectionManager : MonoBehaviour {
	
	GameObject dynamicControllersParent;
	GameObject staticControllersParent;
	public List<GameObject> staticControllers;
	public List<GameObject> dynamicControllers;
	public int activeIndex;
	private int lastActiveIndex;
	public bool indexChanged;
	private bool dynamicControllerVisibility;
	public bool startHomography = true;
	
	// Use this for initialization
	void Start () {
	
		dynamicControllersParent = GameObject.Find("DynamicControllers");
		staticControllersParent = GameObject.Find("StaticControllers");
		
		//Define Lists
		staticControllers = new List<GameObject>();
		dynamicControllers = new List<GameObject>();
		
		//intiate activeIndex
		activeIndex = 0;
		lastActiveIndex = 0;
		indexChanged = false;
		
		//Dynamic Controller Visibility
		dynamicControllerVisibility = true;
		
		startHomography = true;
		
		
		//Turn off visibility of static controllers
		foreach(Transform child in staticControllersParent.transform){
			staticControllers.Add(child.gameObject);
			child.renderer.enabled = false;
		}	
		
		//Change the colour of the dynamic controllers and add the DynamicController Script as a Component
		foreach(Transform child in dynamicControllersParent.transform){
			dynamicControllers.Add (child.gameObject);
			child.gameObject.AddComponent<DynamicController>();
			child.renderer.material.color = Color.red;
		}
		
	}
	
	// Update is called once per frame
	void Update () {
		
		if(indexChanged == true){
			
			//Change colour of active controller to green
			indexChanged = false;
			dynamicControllers[lastActiveIndex].renderer.material.color = Color.red;
			lastActiveIndex = activeIndex;
			dynamicControllers[activeIndex].renderer.material.color = Color.green;
						
		}
		
		//Toggle dynamic controllers visibility
		
		if(Input.GetButtonUp("ToggleController")){
			if(dynamicControllerVisibility == true){
				dynamicControllerVisibility = false;
				foreach(Transform child in dynamicControllersParent.transform){
					child.renderer.enabled = false;
				}
			}
			else {
				dynamicControllerVisibility = true;
				foreach(Transform child in dynamicControllersParent.transform){
					child.renderer.enabled = true;
				}
				
			}
		}		
	}
	
}
