using UnityEngine;
using System.Collections;


public class DynamicController : MonoBehaviour {
	
	SelectionManager manager;
	private Vector3 screenPoint;
	private Vector3 offset;
	
	void Start(){
		
		GameObject selectionManager = GameObject.Find("Selection Manager");
		manager = selectionManager.GetComponent<SelectionManager>();
		
	}

	void OnMouseDown(){
		
		//Assign current controller index to selectionManager.activeIndex
		string name = gameObject.name;
		manager.indexChanged = true;
		manager.activeIndex =  int.Parse(name[13].ToString()) - 1;
		
		screenPoint = Camera.main.WorldToScreenPoint(gameObject.transform.position);
    	offset = gameObject.transform.position - Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z));
		
		
	}
	
	void OnMouseDrag(){
		
		Vector3 curScreenPoint = new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z);
    	Vector3 curPosition = Camera.main.ScreenToWorldPoint(curScreenPoint) + offset;
    	gameObject.transform.position = curPosition;
		
	}
}
