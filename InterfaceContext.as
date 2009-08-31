package com.collectivecolors.extensions.as3.context
{
  //----------------------------------------------------------------------------
  // Imports
  
  import com.collectivecolors.emvc.interfaces.IContext;
  import com.collectivecolors.emvc.interfaces.IExtension;
  import com.collectivecolors.emvc.patterns.extension.Extension;
  
  import org.as3commons.reflect.ClassUtils;
  import org.as3commons.reflect.Type;
  
  //----------------------------------------------------------------------------
  
  public class InterfaceContext extends Extension implements IContext
  {
    //--------------------------------------------------------------------------
    // Properties
    
    protected static var interfaceMap : Object;
    protected static var registeredExtensions : Object;
        
    protected var _interfaces : Array;
    protected var _requireAll : Boolean;
    
    //--------------------------------------------------------------------------
    // Constructor
    
    public function InterfaceContext( extensionName : String,
                                      interfaces : Array   = null, 
                                      requireAll : Boolean = false )
    {
      super( extensionName );
      
      // Only one instance.
      if ( interfaceMap == null )
      {
        interfaceMap         = new Object( );
        registeredExtensions = new Object( );
        
        // Make sure we have the most up to date list of extensions.
        for each ( var extension : IExtension in facade.listExtensions( ) )
        {
          registerExtension( extension );
        }
      }
      
      this.interfaces = interfaces;
      this.requireAll = requireAll;
    }
    
    //--------------------------------------------------------------------------
    // Accessor / modifiers
    
    public function get interfaces( ) : Array
    {
      return _interfaces;  
    }
    
    public function set interfaces( values : Array ) : void
    {
      if ( values == null )
      {
        _interfaces = new Array( );
      }
      else
      {
        _interfaces = values;
        
        // Make sure interfaceMap elements are initialized so we can avoid some
        // performance bottlenecks when we filter the extensions.
        for each ( var interfaceName : String in values )
        {
          if ( ! interfaceMap.hasOwnProperty( interfaceName ) )
          {
            interfaceMap[ interfaceName ] = new Object( );
          }
        }
      }
    }
    
    public function get requireAll( ) : Boolean
    {
      return _requireAll;  
    }
    
    public function set requireAll( value : Boolean ) : void
    {
      _requireAll = value;
    }
    
    //--------------------------------------------------------------------------
    // Extension hooks
    
    /**
     * Implementation of hook registerExtension( ... )
     * 
     * @param extension the extension instance being registered.
     */ 
    public function registerExtension( extension : IExtension ) : void
    {
      var extensionName : String = extension.getExtensionName( );
      
      // If we have already registered this extension, then skip.
      if ( registeredExtensions.hasOwnProperty( extensionName ) ) return;
      
      var type : Type        = Type.forInstance( extension );
      var interfaces : Array = ClassUtils.getFullyQualifiedImplementedInterfaceNames( type.clazz, true );
			
			// Add reference to list of extension implemented interfaces.			
			for each ( var interfaceName : String in interfaces )
			{
			  if ( ! interfaceMap.hasOwnProperty( interfaceName ) )
			  {
			    interfaceMap[ interfaceName ] = new Object( );
			  }
			  
			  interfaceMap[ interfaceName ][ extensionName ] = extension;
			}
			
			// Mark this extension as being registered so we avoid duplicating 
			// our registration call.
			registeredExtensions[ extensionName ] = true;  
    }
    
    /**
     * Implementation of hook removeExtension( ... )
     * 
     * @param extension the extension instance being removed.
     */ 
    public function removeExtension( extension : IExtension ) : void
    {
      var extensionName : String = extension.getExtensionName( );
      
      // If we have already removed this extension, then skip.
      if ( ! registeredExtensions.hasOwnProperty( extensionName ) ) return;
      
      // Remove this extension from all registered interfaces.
      for ( var interfaceName : String in interfaceMap )
      {
        delete interfaceMap[ interfaceName ][ extensionName ];
      }
      
      // Remove this extension from the mapping of registered extensions.
      delete registeredExtensions[ extensionName ];
    } 
    
    //--------------------------------------------------------------------------
    // Context methods
    
    /**
     * Filter down registered extensions to a desired set.
     * 
     * Each context can define whatever properties or methods to act on the 
     * extension array that is passed from the extension manager.
     * 
     * @param extensionMap a map of all registered extensions
     * @return a list of selected extensions filtered and sorted by some criteria
     */
    public function filterExtensions( extensionMap : Object ) : Array
    {
      var extensions : Array = new Array( );
      
      // Go through registered extensions.
      for ( var extensionName : String in extensionMap )
      {
        var validExtension : Boolean = ( requireAll ? true : false );
        
        // Look for implemented interfaces.
        for each ( var interfaceName : String in interfaces )
        {
          if ( interfaceMap[ interfaceName ].hasOwnProperty( extensionName ) )
          {
            if ( ! requireAll )
            {
              validExtension = true;
            }             
          }
          else if ( requireAll )
          {
            validExtension = false;
          }
        }
        
        // If our criteria is met, add extension to the filtered extensions.
        if ( validExtension )
        {
          extensions.push( extensionMap[ extensionName ] );
        } 
      }
      
      return extensions;  
    }

    /**
     * Process extension return values.
     * 
     * This is called after the extensions have executed and returned.
     * 
     * @param values map of extension return values.
     * @return array of extension return values.
     */ 
    public function returnValues( values : Object ) : *
    {
      var list : Array = new Array( );
      
      // Just return an array of all extension values.
      // !! You can override this in a sub class to format your own return values !!
      for ( var extensionName : String in values )
      {
        list.push( values[ extensionName ] );  
      }
      
      return list;
    }
  }
}