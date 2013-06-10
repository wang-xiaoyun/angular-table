# author: Samuel Mueller http://github.com/ssmm

angular.module "angular-table", []

angular.module("angular-table").service "attributeExtractor", () ->
  {
    extractWidth: (classes) ->
      width = /([0-9]+px)/i.exec classes
      if width then width[0] else ""

    isSortable: (classes) ->
      sortable = /(sortable)/i.exec classes
      if sortable then true else false

    extractTitle: (td) ->
      td.attr("title") || td.attr("attribute")

    extractAttribute: (td) ->
      td.attr("attribute")

  }

angular.module("angular-table").directive "atTable", ["attributeExtractor", (attributeExtractor) ->

  capitaliseFirstLetter = (string) ->
    string.charAt(0).toUpperCase() + string.slice(1)

  constructHeader = (element) ->
    thead = element.find "thead"

    if thead[0]

      tr = thead.find "tr"

      existing_ths = {}

      for th in tr.find "th"
        th = angular.element(th)
        existing_ths[th.attr("attribute")] = th.html()

      tr.remove()

      tds = element.find("td")

      tr = $("<tr></tr>")
      for td in tds
        td = angular.element(td)
        attribute = attributeExtractor.extractAttribute(td)
        th = $("<th style='cursor: pointer; -webkit-user-select: none;'></th>")
        title = existing_ths[attribute] || capitaliseFirstLetter(attributeExtractor.extractTitle(td))
        th.html("#{title}")

        sortable = td[0].attributes.sortable || attributeExtractor.isSortable(td.attr("class"))
        if sortable
          th.attr("ng-click", "predicate = '#{attribute}'; descending = !descending;")
          icon = angular.element("<i style='margin-left: 10px;'></i>")
          icon.attr("ng-class", "getSortIcon('#{attribute}')")
          th.append(icon)

        width = attributeExtractor.extractWidth(td.attr("class"))
        th.attr("width", width)
        tr.append(th)

      thead.append tr

  {
    restrict: "AC"
    scope: true
    compile: (element, attributes, transclude) ->


      paginationName = attributes.pagination

      listName = attributes.list || "#{paginationName}.list"

      constructHeader(element)

      tbody = element.find "tbody"
      tr = tbody.find "tr"

      tr.attr("ng-repeat", "item in #{listName} | limitTo:fromPage() | limitTo:toPage() | orderBy:predicate:descending")

      {
        post: ($scope, $element, $attributes) ->

          $scope.getSortIcon = (predicate) ->
            return "icon-minus" if predicate != $scope.predicate
            if $scope.descending then "icon-chevron-down" else "icon-chevron-up"

          $scope.fromPage = () ->
            if $scope[paginationName]
              $scope[paginationName].fromPage()
            else
              $scope.list.length

          $scope.toPage = () ->
            if $scope[paginationName]
              $scope[paginationName].itemsPerPage
            else
              $scope.list.length
      }
  }
]

angular.module("angular-table").directive "atImplicit", ["attributeExtractor", (attributeExtractor) ->
  {
    restrict: "AC"
    compile: (element, attributes, transclude) ->
      attribute = attributeExtractor.extractAttribute element
      element.append "{{item.#{attribute}}}"
  }
]

angular.module("angular-table").directive "atPagination", ["attributeExtractor", (attributeExtractor) ->
  {
    replace: true
    restrict: "E"
    template: "
      <div class='pagination' style='margin: 0px;'>
        <ul>
          <li ng-class='{disabled: stub.currentPage <= 0}'>
            <a href='' ng-click='goToPage(stub.currentPage - 1)'>&laquo;</a>
          </li>
          <li ng-class='{active: stub.currentPage == page}' ng-repeat='page in pages'>
            <a href='' ng-click='goToPage(page)'>{{page + 1}}</a>
          </li>
          <li ng-class='{disabled: stub.currentPage >= stub.numberOfPages - 1}'>
            <a href='' ng-click='goToPage(stub.currentPage + 1); normalize()'>&raquo;</a>
          </li>
        </ul>
      </div>"
    scope: {
      itemsPerPage: "@"
      instance: "="
      list: "="
    }
    link: ($scope, $element, $attributes) ->
      $scope.stub = {}

      $scope.stub.list = $scope.list

      $scope.stub.itemsPerPage = $scope.itemsPerPage

      $scope.stub.currentPage = 0

      $scope.update = () ->
        $scope.stub.numberOfPages = Math.ceil($scope.list.length / $scope.stub.itemsPerPage)
        $scope.pages = for x in [0..($scope.stub.numberOfPages - 1)]
          x
        $scope.stub.list = $scope.list

      $scope.stub.fromPage = () ->
        $scope.stub.itemsPerPage * $scope.stub.currentPage - $scope.list.length

      $scope.goToPage = (page) ->
        if page < 0
          page = 0
        else if page > $scope.stub.numberOfPages - 1
          page = $scope.stub.numberOfPages - 1

        $scope.stub.currentPage = page

      $scope.update()

      $scope.instance = $scope.stub

      $scope.$watch "list", () ->
        $scope.update()
  }
]